class SubscriptionsController < ApplicationController
  def new
    @fee = SubscriptionFee.on_sale.find_by(id: params[:subscription_fee_id])
    redirect_to shop_path unless @fee
    @sub = Subscription.new(subscription_fee: @fee, season_desc: @fee.season_desc)
  end

  def create
    @sub = Subscription.new(subscription_params)
    @fee = @sub.subscription_fee

    if @sub.save
      cart = current_cart(:create)
      cart_item = CartItem.create(cart: cart, cartable: @sub, description: @fee.full_description, cost: @fee.cost)
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
