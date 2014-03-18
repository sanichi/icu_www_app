module PaymentsHelper
  def payment_method_menu(selected, opt={paid: true, unpaid: true})
    meths = Kart::PAYMENT_METHODS.map { |m| [t("shop.payment.method.#{m}"), m] }
    meths.unshift [t("shop.payment.paid"), "paid"] if opt[:paid]
    meths.push [t("shop.payment.unpaid"), "unpaid"] if opt[:unpaid]
    options_for_select(meths, selected)
  end

  def card_mm_menu
    months = (1..12).map { |m| "%02d" % m }
    months.unshift [t("shop.payment.card.mm"), ""]
    options_for_select(months)
  end

  def card_yyyy_menu
    year = Date.today.year
    years = 11.times.each_with_object([]) { |d, a| y = year + d; a.push [y, y] }
    years.unshift [t("shop.payment.card.yyyy"), ""]
    options_for_select(years)
  end

  def cart_status_menu(selected, default="any")
    counties = Kart.statuses.map { |s| [t("shop.payment.status.#{s}"), s] }
    counties.unshift [t(default), ""]
    options_for_select(counties, selected)
  end
end
