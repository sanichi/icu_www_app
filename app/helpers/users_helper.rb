module UsersHelper
  def theme_menu(selected)
    options_for_select User::THEMES, selected
  end

  def locale_menu(selected)
    options_for_select User::LOCALES.map { |locale| [t("user.lang.#{locale}"), locale] }, selected
  end
end
