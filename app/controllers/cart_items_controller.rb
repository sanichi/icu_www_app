class CartItemsController < ApplicationController
  def destroy
    cart_item = current_cart.cart_items.find do |item|
      item.id = params[:id].to_i
    end
    cart_item.destroy
    redirect_to cart_path
  rescue
    redirect_to shop_path
  end
end
