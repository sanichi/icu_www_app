# encoding: utf-8

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
    options_for_select User::ROLES.map { |r| [t("user.role.#{r}", locale: "en"), r] }, selected.try(:split)
  end

  def admin_user_search_role(selected)
    choices = []
    choices << ["Any Role",   "any"]
    choices << ["Some Role", "some"]
    choices << ["No Role",   "none"]
    choices.concat(User::ROLES.map { |r| [t("user.role.#{r}", locale: "en"), r] })
    options_for_select choices, selected
  end

  def admin_user_search_expiry(selected)
    options_for_select(["Any Expiry", "Active", "Expired", "Extended"], selected)
  end

  def admin_user_search_verify(selected)
    options_for_select(["Any Verified", "Verified", "Unverified"], selected)
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
  
  def pagination_links(pager)
    links = Array.new
    links.push(link_to t("pagination.frst"), pager.frst_page) if pager.after_start
    links.push(link_to t("pagination.next"), pager.next_page) if pager.before_end
    links.push(link_to t("pagination.prev"), pager.prev_page) if pager.after_start
    links.push(link_to t("pagination.last"), pager.last_page) if pager.before_end
    raw "#{pager.min_and_max} #{t('pagination.of')} #{pager.count} #{links.size > 0 ? '∙' : ''} #{links.join(' ∙ ')}"
  end
end
