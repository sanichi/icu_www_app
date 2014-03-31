class ItemsController < ApplicationController
  def new
    @fee = Fee.on_sale.where(id: params[:fee_id]).first
    if @fee
      @item = Item.new(fee: @fee, type: @fee.subtype(:item)).becomes(Item)
      @new_player = NewPlayer.new if @fee.new_player_allowed?
    else
      redirect_to shop_path
    end
  end

  def create
    @item = Item.new(item_params)
    @fee = @item.fee
    cart = current_cart(:create)

    if !cart.duplicates?(@item, add_error: true) && @item.save
      cart.items << @item
      redirect_to cart_path
    else
      flash_first_base_error(@item)
      @item = @item.becomes(Item)
      @new_player = NewPlayer.new if @fee.subtype == "subscription"
      render "new"
    end
  end

  def destroy
    item = current_cart.items.find do |item|
      item.id == params[:id].to_i && item.unpaid?
    end
    item.destroy
    redirect_to cart_path
  rescue
    redirect_to shop_path
  end

  private

  def item_params
    params[:item].permit(:type, :fee_id, :player_id, :player_data)
  end
end
