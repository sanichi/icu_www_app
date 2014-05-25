class String
  def trim
    strip.gsub(/\s+/, " ")
  end

  def trim!
    replace(trim)
  end

  def markoff
    gsub(/<\/?\w+[^>]*\/?>/, "")
  end

  def markoff!
    replace(markoff)
  end

  ICU_MARKUP = /\[
    (ART|IML|PGN|TRN|UPL)
    :([1-9]\d*)
    :([^<>\[\]\n\r:]*)
    (:[^<>\[\]\n\r:\s"]*)*
  \]/x

  def icu_markup
    gsub(ICU_MARKUP) do |str|
      code = $1
      id   = $2
      text = $3
      opts = $4.to_s.split(":").each_with_object({}) do |option, hash|
        if option.match(/\A([^=]+)=([^=]+)\z/)
          hash[$1] = $2
        elsif option.present? && !option.match(/=/)
          hash[option] = nil
        end
      end
      atrs = {}
      case code
      when "ART"
        atrs[:href] = "/articles/#{id}"
      when "IML"
        atrs[:href] = "/images/#{id}"
      when "PGN"
        atrs[:href] = "/games/#{id}"
      when "TRN"
        atrs[:href] = "/tournaments/#{id}"
      when "UPL"
        atrs[:href] = "/uploads/#{id}"
      end
      if atrs[:href]
        format '<a %s>%s</a>', atrs.to_a.map{ |p| '%s="%s"' % p }.join(" "), text
      else
        str
      end
    end
  end
end
