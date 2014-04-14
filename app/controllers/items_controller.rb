class ItemsController < ApplicationController
  def new
    unless @fee
      @fee = Fee.on_sale.where(id: params[:fee_id]).first
      if @fee
        @item = Item.new(fee: @fee, type: @fee.subtype(:item)).becomes(Item)
        @new_player = NewPlayer.new if @fee.new_player_allowed?
      else
        redirect_to shop_path
      end
    end
  end

  def create
    @item = Item.new(item_params)
    @fee = @item.fee
    cart = current_cart(:create)
    original_notes = @item.notes.dup

    if !cart.duplicates?(@item, add_error: true) && @item.save
      @item.update_column(:cart_id, cart.id)
      redirect_to cart_path
    else
      flash_first_error(@item, now: true)
      @new_player = NewPlayer.new if @fee.new_player_allowed?
      @item = @item.becomes(Item)
      @item.notes = original_notes
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
    params.required(:item).permit(:type, :fee_id, :player_id, :player_data, notes: [])
  end
end
