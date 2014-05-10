module Remarkable
  def to_html(text)
    return "" unless text.present?
    renderer = Redcarpet::Render::HTML.new(filter_html: true)
    markdown = Redcarpet::Markdown.new(renderer, no_intra_emphasis: true, autolink: true, strikethrough: true, underline: true)
    markdown.render(text).html_safe
  end
end
