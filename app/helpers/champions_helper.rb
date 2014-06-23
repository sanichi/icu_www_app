module ChampionsHelper
  def champion_category_menu(selected, default="champion.category.any")
    cats = Champion::CATEGORIES.map { |cat| [t("champion.category.#{cat}"), cat] }
    cats.unshift [t(default), ""]
    options_for_select(cats, selected)
  end
end
