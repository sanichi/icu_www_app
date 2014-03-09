module FeesHelper
  def fee_type_menu(selected)
    types = [
      [t("please_select"), ""],
      [t("fee.type.subscription"), "Fee::Subscripsion"],
      [t("fee.type.entry"), "Fee::Entri"],
    ]
    options_for_select(types, selected)
  end
end
