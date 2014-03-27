class Cart < ActiveRecord::Base
  include Payable
  extend Util::Pagination

  has_many :items, dependent: :destroy
  has_many :payment_errors, dependent: :destroy
  has_many :refunds, dependent: :destroy
  belongs_to :user

  scope :include_items, -> { includes(items: [:fee, :player]) }
  scope :include_errors, -> { includes(:payment_errors) }
  scope :include_refunds, -> { includes(refunds: { user: :player }) }

  def total_cost
    items.map(&:cost).reduce(0.0, :+)
  end

  def refundable?
    active? && payment_method == "stripe"
  end

  def does_not_already_have?(new_item)
    return true if items.none? do |item|
      new_item.duplicate_of?(item, :add_error)
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
    self.status = "paid"
    self.payment_method = "stripe"
    self.payment_ref = charge.id
    self.payment_completed = Time.now
    items.each { |item| item.complete(payment_method) }
  ensure
    self.total = total
    self.original_total = total
    self.payment_name = name
    self.confirmation_email = email
    self.user = user unless user.guest?
    save
  end

  def refund(item_ids, user)
    refund = Refund.new(user: user, cart: self)
    charge = Stripe::Charge.retrieve(payment_ref)
    refund.amount = refund_amount(item_ids, charge)
    charge.refund(amount: cents(refund.amount))
  rescue => e
    refund.error = e.message
    refund
  else
    items.each do |item|
      if item_ids.include?(item.id)
        item.update_column(:status, "refunded")
      end
    end
    self.status = self.total == refund.amount ? "refunded" : "part_refunded"
    self.total -= refund.amount
    save
    refund
  ensure
    refund.save
  end

  def self.search(params, path)
    matches = where(id: params[:id].to_i) if params[:id].to_i > 0
    matches = order(updated_at: :desc)
    matches = matches.where(status: params[:status]) if params[:status].present?
    matches = matches.where("payment_name LIKE ?", "%#{params[:name]}%") if params[:name].present?
    matches = matches.where("confirmation_email LIKE ?", "%#{params[:email]}%") if params[:email].present?
    if params[:date].present?
      date = "%#{params[:date]}%"
      matches = matches.where("created_at LIKE ? OR updated_at LIKE ?", date, date)
    end
    paginate(matches, params, path)
  end

  private

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
    payment_errors.build(message: message, details: details, payment_name: name, confirmation_email: email)
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
