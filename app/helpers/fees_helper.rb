module FeesHelper
  def fee_type_menu(selected, default)
    types = [
      [default, ""],
      [t("fee.type.subscription"), "Fee::Subscription"],
      [t("fee.type.entry"), "Fee::Entri"],
    ]
    options_for_select(types, selected)
  end

  def fee_sale_menu(selected)
    sales = [
      ["On sale now", "current"],
      ["No longer on sale", "past"],
      ["Not yet on sale", "future"],
      ["All", "all"],
    ]
    options_for_select(sales, selected)
  end
end
