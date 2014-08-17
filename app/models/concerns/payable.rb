module Payable
  extend ActiveSupport::Concern

  INACTIVE = %w[unpaid refunded]
  ACTIVE = %w[paid part_refunded]
  STATUSES = INACTIVE + ACTIVE

  ONLINE = %w[paypal stripe]
  OFFLINE = %w[cheque cash free]
  PAYMENT_METHODS = ONLINE + OFFLINE

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

  def online?
    ONLINE.include?(payment_method)
  end

  def offline?
    OFFLINE.include?(payment_method)
  end
end
