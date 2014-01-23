module PaymentsHelper
  def payment_method_menu(selected, opt={paid: true, unpaid: true})
    meths = Payment::METHODS.map { |m| [t("shop.payment.method.#{m}"), m] }
    meths.unshift [t("shop.payment.paid"), "paid"] if opt[:paid]
    meths.push [t("shop.payment.unpaid"), "unpaid"] if opt[:unpaid]
    options_for_select(meths, selected)
  end
end
