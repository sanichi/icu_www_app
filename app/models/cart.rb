class Cart < ActiveRecord::Base
  include Pageable
  include Payable

  MAX_AMOUNT = 10000000.00
  MIN_AMOUNT = 0.0

  has_many :items, dependent: :destroy
  has_many :payment_errors, dependent: :destroy
  has_many :refunds, dependent: :destroy
  belongs_to :user

  validates :total, :original_total, numericality: { less_than: MAX_AMOUNT }, allow_nil: true

  scope :include_items_plus, -> { includes(items: [:fee, :player]) }
  scope :include_items, -> { includes(:items) }
  scope :include_errors, -> { includes(:payment_errors) }
  scope :include_refunds, -> { includes(refunds: { user: :player }) }

  def total_cost
    items.map(&:cost).reduce(0.0, :+)
  end

  def refundable?
    active? && payment_method == "stripe"
  end

  def duplicates?(new_item, add_error: false)
    items.each do |item|
      if error = new_item.duplicate_of?(item)
        new_item.errors.add(:base, error) if add_error
        return true
      end
    end
    false
  end

  def last_payment_error_message
    payment_errors.last.try(:message).presence || "None"
  end

  def purchase(params, user)
    token, name, email = %i[stripe_token payment_name confirmation_email].map { |n| params[n].presence }
    total = total_cost
    charge = Stripe::Charge.create(
      amount: cents(total),
      currency: "eur",
      card: token,
      description: ["Cart #{id}", name, email].reject { |d| d.nil? }.join(", ")
    )
  rescue Stripe::CardError => e
    add_payment_error(e, name, email)
  rescue => e
    add_payment_error(e, name, email, "Something went wrong, please contact webmaster@icu.ie")
  else
    successful_payment("stripe", charge.id)
  ensure
    update_cart(total, name, email, user)
    send_receipt
  end

  def pay_with_cash(cash_payment, user)
    successful_payment(cash_payment.payment_method)
    update_cart(cash_payment.amount, cash_payment.name, cash_payment.email, user)
    send_receipt
  end

  def refund(item_ids, user)
    refund = Refund.new(user: user, cart: self)
    charge = Stripe::Charge.retrieve(payment_ref)
    refund.amount = refund_amount(item_ids, charge)
    charge.refund(amount: cents(refund.amount))
    items.each do |item|
      if item_ids.include?(item.id)
        item.update_column(:status, "refunded")
      end
    end
    self.status = self.total == refund.amount ? "refunded" : "part_refunded"
    self.total -= refund.amount
    save!
    refund
  rescue => e
    refund.error = e.message
    refund
  ensure
    refund.save
  end

  def self.search(params, path)
    params[:status] = "active" if params[:status].nil?
    matches = order(updated_at: :desc).include_items
    matches = where(id: params[:id].to_i) if params[:id].to_i > 0
    if STATUSES.include?(params[:status])
      matches = matches.where(status: params[:status])
    elsif params[:status].match(/\A(in)?active\z/)
      matches = matches.send(params[:status])
    end
    matches = matches.where("payment_name LIKE ?", "%#{params[:name]}%") if params[:name].present?
    matches = matches.where("confirmation_email LIKE ?", "%#{params[:email]}%") if params[:email].present?
    if params[:date].present?
      date = "%#{params[:date]}%"
      matches = matches.where("created_at LIKE ? OR updated_at LIKE ?", date, date)
    end
    paginate(matches, params, path)
  end

  def all_notes
    items.each_with_object({}) do |item, notes|
      item.notes.each do |note|
        notes[note] ||= notes.size + 1
      end
    end
  end

  private

  def successful_payment(payment_method, charge_id=nil)
    self.status = "paid"
    self.payment_method = payment_method
    self.payment_ref = charge_id
    self.payment_completed = Time.now
    items.each { |item| item.complete(payment_method) }
  end

  def update_cart(total, name, email, user)
    self.total = total
    self.original_total = total
    self.payment_name = name
    self.confirmation_email = email
    self.user = user unless user.guest?
    save
  end

  def send_receipt
    return unless paid?
    mail = IcuMailer.payment_receipt(id)
    update_column(:confirmation_text, mail.body.decoded)
    raise "no email address available" unless confirmation_email.present?
    mail.deliver
    update_column(:confirmation_sent, true)
  rescue => e
    update_columns(confirmation_sent: false, confirmation_error: e.message.gsub(/\s+/, ' ').truncate(255))
  end

  def cents(euros)
    (euros * 100).to_i
  end

  def add_payment_error(error, name, email, message=nil)
    message ||= error.message || "Unknown error"
    details = error.try(:json_body)
    unless details.nil?
      details = details.fetch(:error) { details } if details.is_a?(Hash)
      details.delete(:message) if details.is_a?(Hash) && details[:message] == message
      details = details.to_s
    end
    payment_errors.build(message: message.truncate(255), details: details.truncate(255), payment_name: name.to_s.truncate(100), confirmation_email: email.to_s.truncate(50))
  end

  def refund_amount(item_ids, charge)
    # Check that the cart_items to be refunded all belong to this cart and have "paid" status.
    refund_amount = 0.0
    item_ids.each do |item_id|
      item = items.find_by(id: item_id)
      raise "Cart item #{item_id} does not belong to this cart" unless item
      raise "Cart item #{item_id} has wrong status (#{item.status})" unless item.paid?
      refund_amount += item.cost
    end

    # Check that the ICU cart and Stripe totals are consistent.
    unless cents(original_total) == charge.amount
      raise "Cart amount (#{cents(original_total)}) is inconsistent with Stripe amount (#{charge.amount})"
    end

    # Check any previous refund amounts are consistent.
    cart_refund = cents(original_total) - cents(total)
    unless cart_refund == charge.amount_refunded
      raise "Previous cart refund (#{cart_refund}) is inconsistent with previous Stripe refund (#{charge.amount_refunded})"
    end

    # Check the proposed refund isn't too large.
    if refund_amount > total
      raise "Refund (#{refund_amount}) is larger than remaining cost (#{total})"
    end

    # Check if the whole cart is being refunded.
    total_refunds = items.select{ |c| c.refunded? }.size + item_ids.size
    if total_refunds > items.size
      raise "Too many refunds (#{total_refunds}) for this cart (#{items.size})"
    elsif total_refunds == items.size
      unless refund_amount == total
        raise "Refund amount (#{refund_amount}) doesn't match total (#{total})"
      end
    else
      unless refund_amount < total
        raise "Refund amount (#{refund_amount}) should be less than total (#{total})"
      end
    end

    # Return the refund amount (in Euros).
    refund_amount
  end
end
