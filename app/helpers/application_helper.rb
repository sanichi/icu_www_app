module ApplicationHelper
  def active(controller, action=nil, active="active", inactive="")
    boolean = params[:controller] == controller
    boolean = boolean && params[:action] == action if action
    boolean ? active : inactive
  end
end
