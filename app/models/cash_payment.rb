class CashPayment
  include ActiveModel::Model # see https://github.com/rails/rails/blob/master/activemodel/lib/active_model/model.rb

  ATTRS = %i[first_name last_name email payment_method amount]
  attr_accessor *ATTRS

  PAYMENT_METHODS = Cart::PAYMENT_METHODS.select{ |method| method.match(/\A(cheque|cash)\z/) }

  validates :first_name, :last_name, presence: true
  validates :email, format: { with: Global::EMAIL_RGX }, allow_nil: true
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validates :amount, numericality: { greater_than: 0.0 }

  def initialize(attributes={})
    attributes.each do |name, value|
      public_send("#{name}=", value)
    end
    canonicalize
  end

  def name
    "#{first_name} #{last_name}"
  end

  private

  def canonicalize
    if first_name.present? && last_name.present?
      icu_name = ICU::Name.new(first_name, last_name)
      self.first_name = icu_name.first
      self.last_name = icu_name.last
    end
    self.email = email.present? ? email.gsub(/\s+/, "") : nil
    self.amount = BigDecimal.new(amount).round(2) if amount.present?
  end
end
