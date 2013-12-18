# encoding: utf-8

module ApplicationHelper
  def active(controller, action=nil, active="active", inactive="")
    boolean = params[:controller] == controller
    boolean = boolean && params[:action] == action if action
    boolean ? active : inactive
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
    links.push(link_to t("pagination.frst"), pager.frst_page, remote: pager.remote) if pager.after_start?
    links.push(link_to t("pagination.next"), pager.next_page, remote: pager.remote) if pager.before_end?
    links.push(link_to t("pagination.prev"), pager.prev_page, remote: pager.remote) if pager.after_start?
    links.push(link_to t("pagination.last"), pager.last_page, remote: pager.remote) if pager.before_end?
    raw "#{pager.min_and_max} #{t('pagination.of')} #{pager.count} #{links.size > 0 ? '∙' : ''} #{links.join(' ∙ ')}"
  end

  def last_search(*paths)
    paths.unshift :last_search
    session[paths.join("_").to_sym]
  end

  def euros(amount)
    number_to_currency(amount, precision: 2, unit: "€")
  end
end
