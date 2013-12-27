class EntriesController < ApplicationController
  def new
    @fee = EntryFee.on_sale.find_by(id: params[:entry_fee_id])
    redirect_to shop_path unless @fee
    @entry = Entry.new(entry_fee: @fee)
  end

  def create
    @entry = Entry.new(entry_params)
    @fee = @entry.subscription_fee

    if @entry.save
      cart = current_cart(:create)
      cart_item = CartItem.create(cart: cart, cartable: @entry)
      redirect_to cart_path(cart)
    else
      flash.now.alert = @entry.errors.to_a.first
      render "new"
    end
  end

  private

  def entry_params
    params[:entry].permit(:entry_fee_id, :player_id)
  end
end
