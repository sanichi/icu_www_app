class Refund < ActiveRecord::Base
  belongs_to :cart
  belongs_to :user
  default_scope { order(:created_at) }
end
