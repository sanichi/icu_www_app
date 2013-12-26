class CartItem < ActiveRecord::Base
  belongs_to :cart
  belongs_to :cartable, polymorphic: true, dependent: :destroy

  STATUSES = %w[unpaid paid refunded]

  validates :status, inclusion: { in: STATUSES }
end
