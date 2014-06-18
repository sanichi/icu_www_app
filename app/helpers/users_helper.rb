module UsersHelper
  def user_expiry_menu(selected)
    options_for_select(["Any Expiry", "Active", "Expired", "Extended"], selected)
  end

  def user_locale_menu(selected)
    options_for_select User::LOCALES.map { |locale| [t("user.lang.#{locale}"), locale] }, selected
  end

  def user_roles_menu(selected)
    options_for_select User::ROLES.map { |r| [t("user.role.#{r}", locale: "en"), r] }, selected.try(:split)
  end

  def user_roles_search_menu(selected)
    choices = []
    choices << ["Any Role",   "any"]
    choices << ["Some Role", "some"]
    choices << ["No Role",   "none"]
    choices.concat(User::ROLES.map { |r| [t("user.role.#{r}", locale: "en"), r] })
    options_for_select choices, selected
  end

  def user_status_menu(selected=nil)
    options_for_select(["Any Status", "OK", "Not OK"], selected)
  end

  def user_theme_menu(selected)
    themes = User::THEMES.map do |theme|
      label = theme == User::DEFAULT_THEME ? "#{theme} (#{t("default")})" : theme
      [label, theme]
    end
    options_for_select themes, selected
  end

  def user_verify_menu(selected)
    options_for_select(["Any Verified", "Verified", "Unverified"], selected)
  end
end
