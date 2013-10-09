class Ireland
  PROVINCES =
  {
    "connaught" => %w[galway leitrim mayo roscommon sligo].freeze,
    "leinster"  => %w[carlow dublin kildare kilkenny laois longford louth meath offaly westmeath wexford wicklow].freeze,
    "munster"   => %w[clare cork kerry limerick tipperary waterford].freeze,
    "ulster"    => %w[antrim armagh cavan derry donegal down fermanagh monaghan tyrone].freeze,
  }.freeze
  COUNTIES = Hash[PROVINCES.each_with_object([]){|(p,cs),a| cs.each{|c| a << [c,p]}}.sort].freeze
  
  def self.provinces
    PROVINCES.keys
  end
  
  def self.counties(province=nil)
    if province.blank?
      COUNTIES.keys
    elsif PROVINCES.include?(province.to_s)
      PROVINCES[province.to_s].dup
    else
      []
    end
  end
  
  def self.province(county)
    COUNTIES[county.to_s]
  end

  def self.has?(province, county=nil)
    return false if province.blank?
    counties = PROVINCES[province.to_s]
    return false unless counties
    return true if county.blank?
    counties.include?(county.to_s)
  end
end
