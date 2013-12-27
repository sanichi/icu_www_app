class Cart < ActiveRecord::Base
  has_many :cart_items, dependent: :destroy

  STATUSES = %w[unpaid paid part_refunded refunded]

  validates :status, inclusion: { in: STATUSES }
  
  scope :include_cartables, -> { includes(cart_items: [ :cartable ]) }

  def items
    cart_items.count
  end

  def total
    cart_items.map(&:cartable).map(&:cost).reduce(0.0, :+)
  end
end
