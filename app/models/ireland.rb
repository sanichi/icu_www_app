class Ireland
  PROVINCES =
  {
    "connaught" => %w[galway leitrim mayo roscommon sligo].freeze,
    "leinster"  => %w[carlow dublin kildare kilkenny laois longford louth meath offaly westmeath wexford wicklow].freeze,
    "munster"   => %w[clare cork kerry limerick tipperary waterford].freeze,
    "ulster"    => %w[antrim armagh cavan derry donegal down fermanagh monaghan tyrone].freeze,
  }.freeze
  COUNTIES = Hash[PROVINCES.each_with_object([]){|(p,cs),a| cs.each{|c| a << [c,p]}}.sort].freeze

  def self.province?(province)
    PROVINCES.has_key?(province.to_s)
  end

  def self.county?(county)
    COUNTIES.has_key?(county.to_s)
  end

  def self.has?(province, county)
    return false unless province?(province) && county?(county)
    PROVINCES[province.to_s].include?(county.to_s)
  end

  def self.provinces
    PROVINCES.keys
  end

  def self.counties(province=nil)
    if province.nil?
      COUNTIES.keys
    elsif province?(province)
      PROVINCES[province.to_s].dup
    else
      []
    end
  end

  def self.province(county)
    COUNTIES[county.to_s]
  end
end
