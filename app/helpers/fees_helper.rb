module FeesHelper
  def fee_type_menu(selected)
    types = Fee::TYPES.map do |type|
      [t("fee.type.#{Fee.subtype(type)}"), type]
    end
    types.unshift [t("all"), ""]
    options_for_select(types, selected)
  end

  def fee_sale_menu(selected)
    sales = [
      ["In sale period", "current"],
      ["Sale finished", "past"],
      ["Sale not started", "future"],
      ["All", "all"],
    ]
    options_for_select(sales, selected)
  end

  def fee_active_menu(selected)
    active = [
      ["Active", "true"],
      ["Inactive", "false"],
      ["All", ""],
    ]
    options_for_select(active, selected)
  end
end
