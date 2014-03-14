module Payible
  extend ActiveSupport::Concern
  PAYMENT_METHODS = %w[paypal stripe cheque cash free]

  included do
    def self.active_statuses
      statuses.reject { |s| s == "unpaid" || s == "refunded" }
    end
    def self.inactive_statuses
      statuses.reject { |s| s == "paid" || s == "part_refunded" }
    end
    validates :status, inclusion: { in: statuses }
    validates :payment_method, inclusion: { in: PAYMENT_METHODS }, allow_nil: true
    scope :active, -> { where(status: active_statuses) }
    scope :inactive, -> { where(status: inactive_statuses) }
    statuses.each do |s|
      scope s.to_sym, -> { where(status: s) }
      define_method("#{s}?".to_sym) { status == s }
    end
  end

  def active?
    active_statuses.include?(status)
  end

  def inactive?
    inactive_statuses.include?(status)
  end
end
