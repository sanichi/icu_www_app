class PaymentError < ActiveRecord::Base
  belongs_to :cart
  default_scope { order(:created_at) }
end
