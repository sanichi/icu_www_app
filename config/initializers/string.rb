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

  def obscure
    split(/\./).map do |part|
      part.rot13!
      part.gsub!(/([@.\/])/) { |c| '\\' + '%03o' % c.ord } # $str = preg_replace('/([@.\/])/e', "chr(92) . sprintf('%03o',ord('\\1'))", $str);
      part.gsub!(/'/, "\\\\'")                             # $str = preg_replace("/[']/", "\'", $str);
      "'#{part}'"
    end.reverse.join(", ")
  end

  def rot13
    tr "A-Za-z", "N-ZA-Mn-za-m"
  end

  def rot13!
    replace(rot13)
  end
end
