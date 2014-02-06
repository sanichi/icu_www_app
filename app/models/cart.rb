class Cart < ActiveRecord::Base
  extend Util::Pagination
  include Payable

  has_many :cart_items, dependent: :destroy
  has_many :payment_errors, dependent: :destroy

  scope :include_cartables, -> { includes(cart_items: [:cartable]) }
  scope :include_payment_errors, -> { includes(:payment_errors) }

  def items() cart_items.count end
  def items?() items > 0 end
  def perrors() payment_errors.count end
  def perrors?() perrors > 0 end

  def total_cost
    cart_items.map(&:cartable).map(&:cost).reduce(0.0, :+)
  end

  def does_not_already_have?(cartable)
    return true if cart_items.none? do |item|
      item.cartable_type == cartable.class.to_s && cartable.duplicate_of?(item.cartable, :add_error)
    end
    false
  end

  def last_payment_error_message
    (payment_errors.last.try(:message).presence || "None").gsub("'", "\\\\'")
  end

  def purchase(params)
    token, name, email = %i[stripe_token payment_name confirmation_email].map { |n| params[n].presence }
    total = total_cost
    charge = Stripe::Charge.create(
      amount: cents(total),
      currency: "eur",
      card: token,
      description: ["Cart #{id}", name, email].reject { |d| d.nil? }.join(", ")
    )
  rescue Stripe::CardError => e
    payment_errors.build(PaymentError.params(e, name, email))
  rescue => e
    payment_errors.build(PaymentError.params(e, name, email, message: "Something went wrong, please contact webmaster@icu.ie"))
  else
    self.status = "paid"
    self.payment_method = "stripe"
    self.payment_ref = charge.id
    self.payment_completed = Time.now
    cart_items.each { |item| item.cartable.update_columns(payment_method: payment_method, status: status) }
  ensure
    self.total = total
    self.original_total = total
    self.payment_name = name
    self.confirmation_email = email
    save
  end

  def self.search(params, path)
    if (id = params[:id].to_i) > 0
      matches = where(id: id)
    else
      matches = order(updated_at: :desc)
      matches = matches.where(status: params[:status]) if params[:status].present?
      matches = matches.where("payment_name LIKE ?", "%#{params[:name]}%") if params[:name].present?
      matches = matches.where("confirmation_email LIKE ?", "%#{params[:email]}%") if params[:email].present?
    end
    paginate(matches, params, path)
  end

  private

  def cents(euros)
    (euros * 100).round
  end
end
