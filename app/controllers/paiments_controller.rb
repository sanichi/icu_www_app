class PaimentsController < ApplicationController
  def xshop
    @fees = Fee.for_sale
    @completed_carts = completed_carts
  end

  def xcart
    redirect_to xshop_path unless check_cart(:create)
  end

  def xcard
    redirect_to xshop_path unless check_cart { !@cart.items.empty? }
  end

  def xcharge
    if check_cart { !@cart.items.empty? && request.xhr? }
      @cart.purchase(params, current_user)
      if @cart.paid?
        complete_cart(@cart.id)
        begin
          IcuMailer.payment_receipt(@cart.id).deliver
        rescue => e
          logger.error "payment receipt for cart #{@cart.id} failed: #{e.message}"
        end
      end
    else
      if request.xhr?
        render nothing: true
      else
        redirect_to xshop_path
      end
    end
  end

  def xconfirm
    @cart = last_completed_cart
    redirect_to xshop_path unless @cart
  end

  def xcompleted
    @completed_carts = completed_carts
  end

  private

  def check_cart(option=nil)
    @cart = current_cart(option)
    @cart && (!block_given? || yield)
  end
end
