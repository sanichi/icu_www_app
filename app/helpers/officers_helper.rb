module OfficersHelper
  def officer_menu(selected)
    officers = Officer.ordered.active.all.map { |o| [t("officer.role.#{o.role}"), o.id] }
    officers.unshift [t("none"), ""]
    options_for_select(officers, selected)
  end
end
