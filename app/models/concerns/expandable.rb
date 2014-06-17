module Expandable
  EXPANDABLE = {
    "ART" => { class: Article, title: /\S/ },
    "EVT" => { class: Event, name: /\S/, title: /\S/ },
    "GAM" => { class: Game, text: /\S/ },
    "IMG" => { class: Image, height: /\A[1-9]\d*\z/, width: /\A[1-9]\d*\z/, align: /\A(center|left|right)\z/, margin: /\A(yes|no)\z/, alt: /\S/ },
    "IML" => { class: Image, text: /\S/ },
    "PGN" => { class: Game, text: /\S/ },
    "TRN" => { class: Tournament, name: /\S/, title: /\S/ },
    "UPL" => { class: Upload, text: /\S/ },
  }
  SPECIAL = {
    "EMA" => nil,
    "FEN" => { align: /\A(center|left|right)\z/, style: Board::VALID_STYLE, comment: /\S/ },
  }

  def expand_all(text)
    text.gsub(/\[(#{EXPANDABLE.keys.join('|')}):([1-9]\d*)(:[^\]]+)?\]/) do
      expand_each(EXPANDABLE[$1][:class], $2.to_i, options($1, $3))
    end.gsub(/\[(#{SPECIAL.keys.join('|')}):([^:]+)(?::(.*))?\]/) do
      expand_special($1, $2, $3)
    end
  end

  private

  def expand_each(klass, id, options)
    klass.find(id).expand(options)
  rescue ActiveRecord::RecordNotFound => e
    "[Error: no #{klass} #{id}]"
  rescue => e
    "[Error: #{e.message}]"
  end

  def expand_special(type, data, option)
    case type
    when "EMA"
      raise "invalid email (#{data})" unless data.match(/\A[^.@\s][^@\s]*@[^.@\s]+(\.[^@\s]+)+\z/)
      link = %Q{<a href="mailto:#{data}">#{option || data}</a>}
      "<script>liame(#{link.obscure})</script>"
    when "FEN"
      board = Board.new(data)
      options = options(type, option)
      board.expand(options)
    else
      raise "unrecognised shortcut type (#{type})"
    end
  rescue => e
    "[Error: #{e.message}]"
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
          hash[k2s] = val if allowed[k2s] && val.match(allowed[k2s])
        else
          match = allowed.find { |k,v| key.match(v) && !hash.has_key?(k) }
          hash[match[0]] = key if match
        end
      end
    end
    hash
  end
end
