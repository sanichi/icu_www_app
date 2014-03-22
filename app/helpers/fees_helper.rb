module FeesHelper
  def fee_type_menu(selected, default)
    types = Fee::TYPES.map do |type|
      [t("fee.type.#{Fee.subtype(type)}"), type]
    end
    types.unshift [default, ""]
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
