class Phone
  attr_reader :int_code, :local_code, :number

  # See http://en.wikipedia.org/wiki/Telephone_numbers_in_the_Republic_of_Ireland.
  IE_LOCAL = '1|2\d|402|404|4[1-7]|49|504|505|5[1-3]|5[6-9]|6\d|7[14]|822|8[3-9]|9[01]|9[3-9]'

  def initialize(str)
    @str = str.to_s.dup
    parse
  end

  def parsed?
    @int_code && @local_code && @number
  end

  def blank?
    @blank
  end

  def mobile?
    @mobile
  end

  def canonical
    if parsed?
      if @int_code == "353"
        "(0#{@local_code}) #{@number}"
      else
        "+#{@int_code} #{@local_code} #{@number}"
      end
    end
  end

  private

  def parse
    tokenize
    extract_int_code
    extract_local_code
    extract_number
    detect_mobile
  end

  def tokenize
    @str.sub!(/\+/, "00")
    @str.gsub!(/[^\d]/, " ")
    @str.gsub!(/\b(00?)\s+([1-9])/, '\1\2')
    @str.strip!
    @blank = @str.blank?
    @tokens = @str.split(" ")
  end

  def extract_int_code
    return unless @tokens.any?

    if m = @tokens[0].match(/\A00([1-9]\d{0,2})/)
      @int_code = m[1]
      if m.post_match.length == 0
        @tokens.shift
      else
        @tokens[0] = m.post_match
      end
    elsif m = @tokens[0].match(/\A0?#{IE_LOCAL}/)
      @int_code = "353"
    end    
  end

  def extract_local_code
    return unless @int_code && @tokens.any?

    if @int_code == "353"
      if m = @tokens[0].match(/\A0?(#{IE_LOCAL})/)
        @local_code = m[1]
        if m.post_match.length == 0
          @tokens.shift
        else
          @tokens[0] = m.post_match
        end
      end
    elsif m = @tokens[0].match(/\A0?([1-9]\d{0,3})/)
      @local_code = m[1]
      if m.post_match.length == 0
        @tokens.shift
      else
        @tokens[0] = m.post_match
      end
    end
  end

  def extract_number
    return unless @local_code && @tokens.any?

    number = @tokens.each_with_object("") do |token, num|
      num << token if (num.length + token.length) <= 7
    end

    @number = number if number.length >= 5 && number.length <= 7
  end

  def detect_mobile
    if parsed?
      case @int_code
      when "353"
        @mobile = true if @local_code.match(/\A8(3|[5-9])\z/)
      when "44"
        if @local_code.match(/\A7([4-9])/)
          @mobile = true
          fix_uk_mobile
        end
      end
    end
    @mobile = false unless @mobile
  end
  
  def fix_uk_mobile
    if @local_code.length + @number.length == 10 && @local_code.length != 4
      if @local_code.length < 4
        len = 4 - @local_code.length
        @local_code = @local_code + @number[0, len]
        @number = @number[len, 6]
      else
        len = 6 - @number.length
        @number = @number + @local_code[0, len]
        @local_code = @local_code[len, 4]
      end
    end
  end
end
