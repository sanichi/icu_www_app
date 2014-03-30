module CashPaymentsHelper
  def cash_payment_method_menu(selected)
    meths = CashPayment::PAYMENT_METHODS.map { |m| [t("shop.payment.method.#{m}"), m] }
    meths.unshift [t("please_select"), ""]
    options_for_select(meths, selected)
  end
end
