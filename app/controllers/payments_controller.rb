class PaymentsController < ApplicationController
  def cart
    redirect_to shop_path unless check_cart(:create)
  end

  def card
    redirect_to shop_path unless check_cart { @cart.items? }
  end

  def charge
    if check_cart { @cart.items? && request.xhr? }
      @cart.purchase(params)
    else
      if request.xhr?
        render nothing: true
      else
        redirect_to shop_path
      end
    end
  end

  def confirm
    redirect_to shop_path unless check_cart(:paid)
  end

  private

  def check_cart(option=nil)
    @cart = current_cart(option)
    @cart && (!block_given? || yield)
  end
end
