class Ireland
  PROVINCES =
  {
    "connaught" => %w[galway leitrim mayo roscommon sligo].freeze,
    "leinster"  => %w[carlow dublin kildare kilkenny laois longford louth meath offaly westmeath wexford wicklow].freeze,
    "munster"   => %w[clare cork kerry limerick tipperary waterford].freeze,
    "ulster"    => %w[antrim armagh cavan derry donegal down fermanagh monaghan tyrone].freeze,
  }.freeze
  
  def self.provinces
    PROVINCES.keys
  end
  
  def self.counties(province=nil)
    if province.blank?
      PROVINCES.each_with_object([]) { |(k,v), a| a.concat(v) }.sort
    elsif PROVINCES.include?(province.to_s)
      PROVINCES[province.to_s].dup
    else
      []
    end
  end

  def self.has?(province, county=nil)
    return false if province.blank?
    counties = PROVINCES[province.to_s]
    return false unless counties
    return true if county.blank?
    counties.include?(county.to_s)
  end
end
