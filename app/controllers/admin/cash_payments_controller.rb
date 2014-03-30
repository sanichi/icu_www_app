class Admin::CashPaymentsController < ApplicationController
  authorize_resource
  before_action :check_cart

  def new
    @cash_payment = CashPayment.new
    @cash_payment.amount = "%.2f" % current_cart.total_cost
  end

  def create
    @cash_payment = CashPayment.new(cash_payment_params)
    @cash_payment.valid? # for side effect of adding errors
    cart = current_cart

    if @cash_payment.errors[:amount].none?
      total = cart.total_cost
      if @cash_payment.amount != total
        @cash_payment.errors.add(:amount, "should equal cart total (#{'%.2f' % total})")
      end
    end

    if @cash_payment.errors.none?
      cart.pay_with_cash(@cash_payment, current_user)
      complete_cart(cart.id)
      flash[:notice] = t("shop.payment.registered")
      redirect_to shop_path
    else
      @cash_payment.instance_eval { @amount = "%.2f" % @amount rescue @amount }
      render "new"
    end
  end

  private

  def check_cart
    redirect_to shop_path unless current_cart && current_cart.items.any?
  end

  def cash_payment_params
    params[:cash_payment].permit(:first_name, :last_name, :email, :payment_method, :amount)
  end
end
