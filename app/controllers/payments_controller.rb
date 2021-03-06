class PaymentsController < ApplicationController
  def shop
    @fees = Fee.for_sale
    @completed_carts = completed_carts
    @current_season = Season.new
    @next_season = @current_season.next if Date.today.month == 8
  end

  def cart
    redirect_to shop_path unless check_cart(:create)
  end

  def card
    redirect_to shop_path unless check_cart { !@cart.items.empty? }
  end

  def charge
    if check_cart { !@cart.items.empty? && request.xhr? }
      @cart.purchase(params, current_user)
      complete_cart(@cart.id) if @cart.paid?
    else
      if request.xhr?
        render nothing: true
      else
        redirect_to shop_path
      end
    end
  end

  def confirm
    @cart = last_completed_cart
    redirect_to shop_path unless @cart
  end

  def completed
    @completed_carts = completed_carts
  end

  private

  def check_cart(option=nil)
    @cart = current_cart(option)
    @cart && (!block_given? || yield)
  end
end
