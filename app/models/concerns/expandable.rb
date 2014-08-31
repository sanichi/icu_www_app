module Expandable
  EXPANDABLE = {
    "ART" => { class: Article, title: /\S/ },
    "CAL" => { class: Event, name: /\S/, title: /\S/ },
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
    "EXL" => { url: /\A\/\/[^"\s]+\z/, text: /\S/, target: /\A\w+\z/ },
    "FEN" => { align: /\A(center|left|right)\z/, style: Board::VALID_STYLE, comment: /\S/ },
    "RTN" => { text: /\S/ },
  }

  def expand_all(text, raise_exceptions=false)
    text.to_s.gsub(/\[(#{EXPANDABLE.keys.join('|')}):([1-9]\d*)(:[^\]]+)?\]/) do
      begin
        expand_each(EXPANDABLE[$1][:class], $2.to_i, options($1, $3))
      rescue => e
        raise_exceptions ? raise : "(editor shortcut error: #{e.message})"
      end
    end.gsub(/\[(#{SPECIAL.keys.join('|')}):([^:\]]+)(:[^\]]+)?\]/) do
      begin
        expand_special($1, $2, options($1, $3))
      rescue
        raise_exceptions ? raise : "(editor shortcut error: #{e.message})"
      end
    end
  end

  private

  def expand_each(klass, id, options)
    klass.find(id).expand(options)
  rescue ActiveRecord::RecordNotFound => e
    raise "#{id} is not a valid #{klass.to_s.downcase} ID"
  end

  def expand_special(type, data, options)
    case type
    when "EMA"
      # see the hack compensate_redcarpet_ema_escaping in concerns/remarkable.rb necessary for this to function
      raise "#{data} is not a valid email address" unless Global.valid_email?(data)
      link = %Q{<a href="mailto:#{data}">#{options[:text] || data}</a>}
      "<script>liame(#{link.obscure})</script>"
    when "EXL"
      raise "#{data} is not a valid external link" unless data.match(/\Ahttps?\z/)
      raise "missing URL for external link" unless url = options[:url]
      url = data + ":" + url
      raise "invalid URL for external link" unless Global.valid_url?(url)
      target = options[:target] || (url.match(/\Ahttps?:\/\/ratings\.icu\.ie/) ? "ratings" : "external")
      text = options[:text]
      if text.blank?
        text = url.dup
        text.sub!(/\Ahttps?:\/\//, "")
        text.sub!(/\?.*\z/, "")
        text.sub!(/\/\z/, "")
      end
      %Q{<a href="#{url}" target="#{target}">#{text}</a>}
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
    allowed = (EXPANDABLE[type] || SPECIAL[type]).reject{ |k,v| k == :class || k == :type }
    matcher = /\A(#{allowed.keys.join('|')})=(.*)\z/
    opt.to_s.split(/:/).each do |pair|
      if pair.match(matcher)
        key, val = $1, $2
      else
        key, val = nil, pair
      end
      if key.present?
        k2s = key.to_sym
        hash[k2s] = val.markoff if allowed[k2s] && val.match(allowed[k2s])
      else
        match = allowed.find { |k,v| val.match(v) && !hash.has_key?(k) }
        hash[match[0]] = val.markoff if match
      end
    end
    hash
  end
end
