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
end
