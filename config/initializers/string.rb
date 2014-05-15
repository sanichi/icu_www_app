class String
  def trim
    strip.gsub(/\s+/, " ")
  end

  def trim!
    replace(trim)
  end

  def markoff
    gsub(/<\/?\w+\/?>/, "")
  end

  def markoff!
    replace(markoff)
  end
end
