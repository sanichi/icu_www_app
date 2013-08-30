module ApplicationHelper
  def active(controller, action=nil, active="active", inactive="")
    boolean = params[:controller] == controller
    boolean = boolean && params[:action] == action if action
    boolean ? active : inactive
  end
  
  def admin_user_status(selected=nil)
    options_for_select(["Any Status", "OK", "Not OK"], selected)
  end

  def admin_user_roles(selected)
    options_for_select User::ROLES.map { |r| [t("user.role.#{r}"), r] }, selected.try(:split)
  end
  
  def flash_style(name)
    bootstrap_name =
      case name
      when :warning then "warning"
      when :info    then "info"
      when :alert   then "danger"
      else "success"
      end
    "alert alert-#{bootstrap_name}"
  end
end
