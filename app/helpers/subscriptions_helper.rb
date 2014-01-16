module SubscriptionsHelper
  def subscription_category_menu(selected)
    cats = Subscription::CATEGORIES.map { |c| [t("fee.subscription.category.#{c}"), c] }
    cats.unshift [t("fee.subscription.category.any"), ""]
    options_for_select(cats, selected)
  end

  def subscription_season_menu(selected)
    seasons = Subscription.distinct.order(season_desc: :desc).where.not(season_desc: nil).pluck(:season_desc)
    seasons.unshift [t("fee.subscription.any_season"), ""]
    seasons.push [t("none"), "none"]
    options_for_select(seasons, selected)
  end
end

