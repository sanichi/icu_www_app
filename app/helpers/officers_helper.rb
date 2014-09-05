module OfficersHelper
  def officer_menu(selected, please=true)
    officers = Officer.ordered.all.map { |o| [t("officer.role.#{o.role}"), o.id] }
    officers.unshift [t("please_select"), ""] if please
    options_for_select(officers, selected)
  end
end
