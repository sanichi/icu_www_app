module Remarkable
  def to_html(text, filter_html: true)
    return "" unless text.present?
    renderer = Redcarpet::Render::HTML.new(filter_html: filter_html)
    markdown = Redcarpet::Markdown.new(renderer, no_intra_emphasis: true, autolink: true, strikethrough: true, underline: true, tables: true)
    markdown.render(text).html_safe
  end
end
