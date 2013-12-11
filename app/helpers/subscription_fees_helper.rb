module SubscriptionFeesHelper
  def subscription_fee_category_menu(selected)
    cats = SubscriptionFee::CATEGORIES.map { |c| [t("fee.subscription.category.#{c}"), c] }
    options_for_select(cats, selected)
  end
end
