module ItemsHelper
  def item_type_menu(selected, default)
    types = [
      [t(default), ""],
      [t("item.type.subscription"), "Item::Subscription"],
      [t("item.type.entry"), "Item::Entry"],
    ]
    options_for_select(types, selected)
  end

  def item_payment_method_menu(selected, default)
    methods = Cart::PAYMENT_METHODS.map { |m| [t("shop.payment.method.#{m}"), m] }
    methods.unshift [t(default), ""]
    options_for_select(methods, selected)
  end

  def item_status_menu(selected, default)
    statuses = Item::statuses.map { |s| [t("shop.payment.status.#{s}"), s] }
    statuses.unshift [t(default), ""]
    options_for_select(statuses, selected)
  end
end
