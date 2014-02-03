class CartItem < ActiveRecord::Base
  belongs_to :cart
  belongs_to :cartable, polymorphic: true, dependent: :destroy
end
