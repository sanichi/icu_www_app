module Expandable
  EXPANDABLE = {
    "ART" => { class: Article, title: /\S/ },
    "DLD" => { class: Download, text: /\S/ },
    "EVT" => { class: Event, name: /\S/, title: /\S/ },
    "GME" => { class: Game, text: /\S/ },
    "IMG" => { class: Image, height: /\A[1-9]\d*\z/, width: /\A[1-9]\d*\z/, align: /\A(center|left|right)\z/, margin: /\A(yes|no)\z/, alt: /\S/, responsive: /\A(true|false)\z/ },
    "IML" => { class: Image, text: /\S/ },
    "NWS" => { class: News, text: /\S/ },
    "PGN" => { class: Game, text: /\S/ },
    "TRN" => { class: Tournament, name: /\S/, title: /\S/ },
  }
  SPECIAL = {
    "EMA" => { text: /\S/ },
    "FEN" => { align: /\A(center|left|right)\z/, style: Board::VALID_STYLE, comment: /\S/ },
    "RTN" => { text: /\S/ },
  }

  def expand_all(text)
    text.to_s.gsub(/\[(#{EXPANDABLE.keys.join('|')}):([1-9]\d*)(:[^\]]+)?\]/) do
      expand_each(EXPANDABLE[$1][:class], $2.to_i, options($1, $3))
    end.gsub(/\[(#{SPECIAL.keys.join('|')}):([^:\]]+)(:[^\]]+)?\]/) do
      expand_special($1, $2, options($1, $3))
    end
  end

  private

  def expand_each(klass, id, options)
    klass.find(id).expand(options)
  rescue ActiveRecord::RecordNotFound => e
    if ENV["SYNC_#{klass.to_s.upcase}"] && ENV["SYNC_#{klass.to_s.upcase}"].include?("|#{id}|")
      "valid"
    else
      raise "#{id} is not a valid #{klass.to_s.downcase} ID"
    end
  end

  def expand_special(type, data, options)
    case type
    when "EMA"
      raise "#{data} is not a valid email address" unless data.match(/\A[^.@\s][^@\s]*@[^.@\s]+(\.[^@\s]+)+\z/)
      link = %Q{<a href="mailto:#{data}">#{options[:text] || data}</a>}
      "<script>liame(#{link.obscure})</script>"
    when "FEN"
      board = Board.new(data)
      board.expand(options)
    when "RTN"
      raise "#{data} is not a valid rated tournament ID" unless data.match(/\A[1-9]\d*\z/)
      %Q{<a href="http://ratings.icu.ie/tournaments/#{data}" target="ratings">#{options[:text] || data}</a>}
    else
      raise "unrecognised expansion keyword (#{type})"
    end
  end

  def options(type, opt)
    hash = {}
    hash[:type] = type
    opt.to_s.split(/:/).each do |pair|
      key, val = pair.to_s.split(/=/)
      if key.present?
        allowed = (EXPANDABLE[type] || SPECIAL[type]).reject{ |k,v| k == :class || k == :type }
        k2s = key.to_sym
        if val.present?
          hash[k2s] = val.markoff if allowed[k2s] && val.match(allowed[k2s])
        else
          match = allowed.find { |k,v| key.match(v) && !hash.has_key?(k) }
          hash[match[0]] = key.markoff if match
        end
      end
    end
    hash
  end
end
