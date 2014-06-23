class Season
  include Comparable

  attr_reader :error

  def initialize(date_or_desc=Date.today)
    if date_or_desc.is_a?(Date)
      @desc = infer(date_or_desc)
    else
      @desc = parse(date_or_desc.to_s)
    end
  rescue => e
    @error = e.message
  end

  def start
    return nil unless @desc
    Date.new(@desc[0,4].to_i, 9, 1)
  end

  def end
    return nil unless @desc
    Date.new(@desc[0,4].to_i + 1, 8, 31)
  end

  def next
    return nil unless @desc
    year = @desc[0,4].to_i
    Season.new("#{year + 1}-#{(year + 2).to_s[2,2]}")
  end

  def last
    return nil unless @desc
    year = @desc[0,4].to_i
    Season.new("#{year - 1}-#{year.to_s[2,2]}")
  end

  def to_s
    @desc.to_s
  end

  def <=>(another)
    to_s <=> another.to_s
  end

  private

  def parse(desc)
    m = desc.match(/\A\s*(19|20)(\d\d)[^\d]+(\d\d)?(\d\d)\s*\z/)
    raise "syntactically invalid"  unless m
    raise "inconsistent centuries" unless m[3].blank? || m[1] == m[3] || (m[1] == "19" && m[2] == "99" && m[3] == "20" && m[4] == "00")
    raise "inconsistent years"     unless (m[2].to_i + 1 == m[4].to_i) || (m[1] == "19" && m[2] == "99" && m[4] == "00")
    m[1] + m[2] + "-" + m[4]
  end

  def infer(date)
    year = date.year
    year -= 1 if date.month < 9
    year.to_s + "-" + (year + 1).to_s[2,2]
  end
end
