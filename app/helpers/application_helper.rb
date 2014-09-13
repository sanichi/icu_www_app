module ApplicationHelper
  def active?(controller, action=nil)
    controller_name == controller && (action.blank? || action_name == action)
  end

  def active(controller, action=nil)
    active?(controller, action) ? "active" : nil
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

  def auto_submit(klass, on)
    klass + (on ? " auto_submit" : "")
  end

  def to_date(time)
    time.strftime("%Y-%m-%d")
  end

  def formatted_date(date)
    [t("month.s#{date.strftime('%m')}"), date.mday, date.year].join(" ")
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

  # Add an item for the Help dropdown in the top navbar.
  def add_help(page, anchor: nil)
    key = "help.#{page}"
    path = "help_#{page}_path"
    content_for :help do
      content_tag("li") do
        link_to t(key), send(path, anchor: anchor), target: "help"
      end
    end
  end

  # The symbol used for the header control button.
  def header_control_button
    t("symbol.#{show_header?? 'hide' : 'show'}")
  end

  def ok_ko(bool)
    t("symbol.#{bool ? 'ok' : 'ko'}")
  end
end
