class SeasonTicket
  attr_reader :icu_id, :expires_on, :ticket, :error

  def initialize(icu_id_or_ticket, expires_on=nil)
    if expires_on
      @icu_id = icu_id_or_ticket.to_i
      @expires_on = expires_on.to_s
      @ticket = encode
    else
      @ticket = icu_id_or_ticket.to_s
      @icu_id, @expires_on = decode
    end
  rescue => e
    @error = e.message
  end

  def valid?(icu_id=nil, date=nil)
    return false if @error
    return false if icu_id && (!valid_id?(icu_id) || icu_id.to_i != self.icu_id)
    return false if date && (!valid_date?(date) || date.to_s > expires_on)
    true
  end

  def self.standard_config?
    return @standard_config unless @icu_config.nil?
    @standard_config = { base: "af1d3f65fe9dd2b10739ae81a846bd8e", shuffle: "395d57908a4ffffca42f04a1db5af010" }.inject(true) do |m, (k,v)|
      m && Digest::MD5.hexdigest(Rails.application.secrets.season_ticket[k.to_s]) == v
    end
  end

  private

  def base
    Rails.application.secrets.season_ticket["base"]
  end

  def encode
    raise "invalid ICU ID" unless valid_id?(icu_id)
    raise "invalid expiry date" unless valid_date?(expires_on)
    shuffle(to_chars(pack))
  end

  def decode
    raise "invalid season ticket (bad characters)" unless valid_ticket?(ticket)
    unpack(to_decimal(shuffle(ticket)))
  end

  def shuffle(str)
    eval(Rails.application.secrets.season_ticket["shuffle"])
  end

  def to_decimal(str)
    b = base.length
    m = str.length - 1
    n = (0..m).inject(0){ |t, i| t += base.index(str[i]) * b ** (m - i) }.to_s
    raise "invalid season ticket (bad decimal)" unless n.match(/\A[0-9]{7,}\z/)
    n
  end

  def to_chars(str)
    n = str.to_i
    b = base.length
    m = (Math.log10(n) / Math.log10(b)).floor  # highest power of base in number
    (0..m).to_a.reverse.inject("") do |t, i|
      d = b ** i
      p = (n / d).floor
      n-= d * p
      t + base[p]
    end
  end

  def pack
    icu_id.to_s + expires_on[2, 2] + expires_on[5, 2] + expires_on[8, 2]
  end

  def unpack(num)
    raise "invalid season ticket (bad ICU ID)" unless num.match(/\A([1-9]\d*)\d{6}\z/)
    icu_id = $1.to_i
    raise "invalid season ticket (bad expiry date)" unless num.match(/(\d\d)(0[1-9]|1[012])(0[1-9]|[12][0-9]|3[01])\z/)
    expires_on = "20#{$1}-#{$2}-#{$3}"
    [icu_id, expires_on]
  end

  def valid_id?(id)
    id.to_i > 0
  end

  def valid_date?(date)
    date.to_s.match(/\A20\d\d-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])\z/)
  end

  def valid_ticket?(ticket)
    ticket.match(/\A[#{base}]+\z/)
  end
end
