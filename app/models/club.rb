class Club < ActiveRecord::Base
  extend Util::Pagination

  WEB_FORMAT = ['https?:\/\/', '[^.\/\s:]+(\.[^.\/\s:]+){1,}[^\s]+']

  before_validation :normalize_attributes

  validate :county_belongs_to_province, :has_contact_method

  validates :name, presence: true, uniqueness: true
  validates :active, inclusion: { in: [true, false] }
  validates :county, inclusion: { in: Ireland.counties, message: "invalid county" }
  validates :province, inclusion: { in: Ireland.provinces, message: "invalid province" }
  validates :city, presence: true
  validates :contact, presence: true, allow_nil: true
  validates :web, format: { with: /\A#{WEB_FORMAT[0]}#{WEB_FORMAT[1]}\z/ }, allow_nil: true
  validates :email, format: { with: /\A[^\s]+@[^\s]+\z/ }, allow_nil: true
  validates :phone, format: { with: /\d{3}/ }, allow_nil: true
  validates :latitude,  numericality: { greater_than:  51.2, less_than: 55.6 }, allow_nil: true
  validates :longitude, numericality: { greater_than: -10.6, less_than: -5.3 }, allow_nil: true
  validates :district, :address, :meetings, presence: true, allow_nil: true
  
  def contactable?
    phone.present? || email.present? || web.present?
  end
  
  def web_simple
    return unless web
    simple = web.dup
    simple.sub!(/\Ahttps?:\/\//, "")
    simple.sub!(/\/\z/, "")
    simple
  end

  def self.search(params, path)
    matches = order(:name)
    matches = matches.where("name LIKE ?", "%#{params[:name]}%") if params[:name].present?
    matches = matches.where("city LIKE ?", "%#{params[:city]}%") if params[:city].present?
    matches = matches.where("contact LIKE ?", "%#{params[:contact]}%") if params[:contact].present?
    matches = matches.where(province: params[:province]) if params[:province].present?
    matches = matches.where(county: params[:county]) if params[:county].present?
    case params[:active]
    when "true", nil then matches = matches.where(active: true)
    when "false"     then matches = matches.where(active: false)
    end
    paginate(matches, params, path)
  end

  private

  def county_belongs_to_province
    if Ireland.province?(province) && Ireland.county?(county)
      unless Ireland.has?(province, county)
        names = []
        names << I18n.t("ireland.co.#{county}")
        names << I18n.t("ireland.prov.#{Ireland.province(county)}")
        names << I18n.t("ireland.prov.#{province}")
        errors.add(:county, "%s is in %s, not %s" % names)
      end
    end
  end

  def has_contact_method
    if active && !contactable?
      errors[:base] << "An active club must have at least one contact method (phone, email or web)"
    end
  end

  def normalize_attributes
    # Note: 'active' is normalised automatically.
    [:name, :web, :meetings, :address, :district, :city, :latitude, :longitude, :contact, :email, :phone].each do |atr|
      self.send("#{atr}=", nil) if self.send(atr).blank?
    end
    if web.present? && web.match(/\A#{WEB_FORMAT[1]}/)
      self.web = "http://#{web}"
    end
  end
end