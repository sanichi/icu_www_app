class Admin::CartsController < ApplicationController
  authorize_resource

  def index
    @carts = Cart.search(params, admin_carts_path)
    flash.now[:warning] = t("no_matches") if @carts.count == 0
    save_last_search(:admin, :carts)
  end

  def show
    @cart = Cart.include_cartables.include_payment_errors.find(params[:id])
  end

  def show_charge
    @cart = Cart.find(params[:id])
    @charge = Stripe::Charge.retrieve(@cart.payment_ref)
    @json = JSON.pretty_generate(@charge.as_json)
  rescue => e
    @error = e.message
  end
end
