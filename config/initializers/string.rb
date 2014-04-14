class String
  def trim
    strip.gsub(/\s+/, " ")
  end
  def trim!
    replace(trim)
  end
end
