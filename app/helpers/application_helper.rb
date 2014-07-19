module ApplicationHelper
  def active(controller, action=nil, active="active", inactive="")
    boolean = controller_name == controller
    boolean = boolean && action_name == action if action
    boolean ? active : inactive
  end

  def home_page?
    controller_name = "pages" && action_name == "home"
  end

  def flash_style(name)
    bootstrap_name =
      case name.to_s
      when "warning" then "warning"
      when "info"    then "info"
      when "alert"   then "danger"
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

  def last_search(key)
    session["last_search_path_#{key}".to_sym]
  end

  def auto_submit(klass, on)
    klass + (on ? " auto_submit" : "")
  end

  def to_date(time)
    time.strftime("%Y-%m-%d")
  end

  def escape_single_quoted(string, safe=true)
    escaped = string.gsub("'", "\\\\'").gsub(/\n/, "\\n")
    escaped = escaped.html_safe if safe
    escaped
  end

  def mark(mark)
    case mark.to_s
    when "required"  then "*"
    when "defaulted" then "†"
    else ""
    end
  end

  def simple_url(url)
    return unless url
    simple = url.dup
    simple.sub!(/\Ahttps?:\/\//, "")
    simple.sub!(/\/\z/, "")
    simple
  end

  # Used to preserve leading white space in <pre>s which HAML would otherwise suppress.
  def preserve_leading_space(str)
    str.sub(/\A /, "\u00A0")
  end

  # Don't display Irish language features in production (because the translations are incomplete) unless a translator is logged in.
  def irish_enabled?
    Rails.env != "production" || (current_user.translator? && !current_user.admin?)
  end
end
