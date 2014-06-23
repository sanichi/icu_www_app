module Normalizable
  def normalize_blanks(*atrs)
    atrs.each do |atr|
      if self.send(atr).blank?
        self.send("#{atr}=", nil)
      end
    end
  end

  def normalize_newlines(*atrs)
    atrs.each do |atr|
      if self.send(atr).is_a?(String)
        self.send(atr).gsub!(/\r\n/, "\n")
      end
    end
  end
end
