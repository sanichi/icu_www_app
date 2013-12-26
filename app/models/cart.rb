class Cart < ActiveRecord::Base
  has_many :cart_items, dependent: :destroy

  STATUSES = %w[unpaid paid part_refunded refunded]

  validates :status, inclusion: { in: STATUSES }

  def items
    cart_items.count
  end

  def total
    cart_items.map(&:cost).reduce(0.0, :+)
  end
end
