module Payable
  extend ActiveSupport::Concern
  PAYMENT_METHODS = %w[paypal stripe cheque cash free]
  INACTIVE = %w[unpaid refunded]
  ACTIVE = %w[paid part_refunded]
  STATUSES = INACTIVE + ACTIVE

  included do
    validates :status, inclusion: { in: STATUSES }
    validates :payment_method, inclusion: { in: PAYMENT_METHODS }, allow_nil: true
    scope :active, -> { where(status: ACTIVE) }
    scope :inactive, -> { where(status: INACTIVE) }
    STATUSES.each do |s|
      scope s.to_sym, -> { where(status: s) }
      define_method("#{s}?".to_sym) { status == s }
    end
  end

  def active?
    ACTIVE.include?(status)
  end

  def inactive?
    INACTIVE.include?(status)
  end
end
