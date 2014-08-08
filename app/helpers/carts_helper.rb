module CartsHelper
  def euros(amount, precision: 2)
    number_to_currency(amount, precision: precision, unit: "€")
  end

  def cart_status_menu(selected, default="any")
    statuses = Cart::STATUSES.map { |s| [t("shop.payment.status.#{s}"), s] }
    statuses.unshift [t("inactive"), "inactive"]
    statuses.unshift [t("active"), "active"]
    statuses.unshift [t(default), ""]
    options_for_select(statuses, selected)
  end
end
