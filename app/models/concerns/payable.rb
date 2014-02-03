module Payable
  extend ActiveSupport::Concern

  PAYMENT_METHODS = %w[paypal stripe cheque cash free]
  STATUSES = %w[unpaid paid part_refunded refunded]

  included do
    validates :status, inclusion: { in: STATUSES }
    validates :payment_method, inclusion: { in: PAYMENT_METHODS }, allow_nil: true
    STATUSES.each { |s| scope s.to_sym, -> { where(status: s) } }
    scope :active, -> { where(status: ["paid", "part_refunded"]) }
    scope :inactive, -> { where(status: ["unpaid", "refunded"]) }
  end

  STATUSES.each do |s|
    define_method("#{s}?".to_sym) { status == s }
  end

  def active?
    status == "paid" || status == "part_refunded"
  end

  def inactive?
    status == "unpaid" || status == "refunded"
  end
end
