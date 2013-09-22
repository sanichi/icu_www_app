module Admin::UsersHelper
  def expiry_search_menu(selected)
    options_for_select(["Any Expiry", "Active", "Expired", "Extended"], selected)
  end

  def roles_pick_menu(selected)
    options_for_select User::ROLES.map { |r| [t("user.role.#{r}", locale: "en"), r] }, selected.try(:split)
  end

  def roles_search_menu(selected)
    choices = []
    choices << ["Any Role",   "any"]
    choices << ["Some Role", "some"]
    choices << ["No Role",   "none"]
    choices.concat(User::ROLES.map { |r| [t("user.role.#{r}", locale: "en"), r] })
    options_for_select choices, selected
  end

  def status_search_menu(selected=nil)
    options_for_select(["Any Status", "OK", "Not OK"], selected)
  end

  def verify_search_menu(selected)
    options_for_select(["Any Verified", "Verified", "Unverified"], selected)
  end
end
