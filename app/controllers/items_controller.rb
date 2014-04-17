class ItemsController < ApplicationController
  def new
    unless @fee
      @fee = Fee.on_sale.where(id: params[:fee_id]).first
      if @fee
        @item = Item.new(fee: @fee, type: @fee.subtype(:item)).becomes(Item)
        @new_player, @player_name = new_player(@fee)
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
      @new_player, @player_name = new_player(@fee, @item)
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

  def new_player(fee, item=nil)
    new_player = NewPlayer.new if fee.new_player_allowed?
    player_name = ""
    if item
      if item.player_id && (player = Player.find_by(id: item.player_id))
        player_name = player.name(id: true)
      elsif item.player_data && (player = NewPlayer.from_json(item.player_data)) && player.first_name && player.last_name
        new_player = player if fee.new_player_allowed?
        player_name = player.name
      end
    end
    [new_player, player_name]
  end
end
