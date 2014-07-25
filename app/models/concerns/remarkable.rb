module Remarkable
  def to_html(text, filter_html: true)
    return "" unless text.present?
    renderer = Redcarpet::Render::HTML.new(filter_html: filter_html)
    markdown = Redcarpet::Markdown.new(renderer, no_intra_emphasis: true, autolink: true, strikethrough: true, underline: true, tables: true)
    compensate_redcarpet_ema_escaping(markdown.render(text)).html_safe
  end

  private

  def compensate_redcarpet_ema_escaping(string)
    string.gsub(/<script>liame\(.*?\)<\/script>/i) do |match|
      match.gsub("&lt;", "<").gsub("&gt;", ">").gsub("&quot;", '"').gsub("&#39;", "'")
    end
  end
end
