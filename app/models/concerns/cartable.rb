module Cartable
  extend ActiveSupport::Concern

  included do
    has_one :cart_item, as: :cartable
    validates :payment_method, inclusion: { in: Payment::METHODS }, allow_nil: true
    scope :paid, -> { where.not(payment_method: nil) }
    scope :unpaid, -> { where(payment_method: nil) }
  end
  
  def paid?
    payment_method.present?
  end
end
