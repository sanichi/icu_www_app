class Admin::CartsController < ApplicationController
  authorize_resource

  def index
    @carts = Cart.search(params, admin_carts_path)
    flash.now[:warning] = t("no_matches") if @carts.count == 0
    save_last_search(:admin, :carts)
  end

  def show
    @cart = Cart.include_cartables.include_errors.include_refunds.find(params[:id])
  end

  def show_charge
    @cart = Cart.find(params[:id])
    @charge = Stripe::Charge.retrieve(@cart.payment_ref)
    @json = JSON.pretty_generate(@charge.as_json)
  rescue => e
    @error = e.message
  end

  def edit
    @cart = Cart.include_cartables.find(params[:id])
    redirect_to [:admin, @cart] unless @cart.refundable?
  end

  def update
    @cart = Cart.include_cartables.find(params[:id])
    item_ids = params.keys.map{ |k| k.match(/\Aitem_([1-9]\d*)\z/) ? $1.to_i : nil }.compact
    if item_ids.size == 0
      flash.now[:warning] = "Please either click Cancel or select one or more items and then click Refund"
      render "edit"
    else
      refund = @cart.refund(item_ids, current_user)
      if refund.error.present?
        flash.now[:alert] = refund.error
        render "edit"
      else
        flash[:notice] = "Refund was successful"
        redirect_to [:admin, @cart]
      end
    end
  end
end
