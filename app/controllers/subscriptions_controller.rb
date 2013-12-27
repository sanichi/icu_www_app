class SubscriptionsController < ApplicationController
  def new
    @fee = SubscriptionFee.on_sale.find_by(id: params[:subscription_fee_id])
    redirect_to shop_path unless @fee
    @sub = Subscription.new(subscription_fee: @fee, season_desc: @fee.season_desc)
  end

  def create
    @sub = Subscription.new(subscription_params)
    @fee = @sub.subscription_fee
    @sub.category = @fee.category
    @sub.cost = @fee.cost
    cart = current_cart(:create)

    if cart.does_not_already_have?(@sub) && @sub.save
      cart_item = CartItem.create(cart: cart, cartable: @sub)
      redirect_to cart_path(cart)
    else
      flash.now.alert = @sub.errors.to_a.first
      render "new"
    end
  end

  private

  def subscription_params
    params[:subscription].permit(:subscription_fee_id, :player_id, :season_desc)
  end
end
