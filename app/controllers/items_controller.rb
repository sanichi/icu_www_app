class ItemsController < ApplicationController
  def new
    @fee = Fee.on_sale.where(id: params[:fee_id]).first
    if @fee
      @item = Item.new(fee: @fee, type: @fee.subtype(:item)).becomes(Item)
    else
      redirect_to shop_path
    end
  end

  def create
    @item = Item.new(item_params)
    @fee = @item.fee
    cart = current_cart(:create)

    if cart.does_not_already_have?(@item) && @item.save
      cart.items << @item
      redirect_to cart_path(cart)
    else
      flash_first_base_error(@item)
      @item = @item.becomes(Item)
      render "new"
    end
  end

  def destroy
    item = current_cart.items.find do |item|
      item.id = params[:id].to_i
    end
    item.destroy
    redirect_to cart_path
  rescue
    redirect_to shop_path
  end

  private

  def item_params
    params[:item].permit(:type, :fee_id, :player_id)
  end
end

# class EntriesController < ApplicationController
#   def new
#     @fee = EntryFee.on_sale.find_by(id: params[:entry_fee_id])
#     redirect_to shop_path unless @fee
#     @entry = Entry.new(entry_fee: @fee)
#   end
#
#   def create
#     @entry = Entry.new(entry_params)
#     @fee = @entry.entry_fee
#     @entry.description = @fee.description
#     @entry.cost = @fee.cost
#     @entry.event_start = @fee.event_start
#     @entry.event_end = @fee.event_end
#
#     cart = current_cart(:create)
#
#     if @entry.save
#       cart_item = CartItem.create(cart: cart, cartable: @entry)
#       redirect_to cart_path(cart)
#     else
#       flash.now.alert = @entry.errors.to_a.first
#       render "new"
#     end
#   end
#
#   private
#
#   def entry_params
#     params[:entry].permit(:entry_fee_id, :player_id)
#   end
# end
