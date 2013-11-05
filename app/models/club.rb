class Club < ActiveRecord::Base
  extend Util::Pagination

  include Journalable
  journalize %w[name web meet address district city county lat long contact email phone active], "/clubs/%d"

  has_many :players

  WEB_FORMAT = ['https?:\/\/', '[^.\/\s:]+(\.[^.\/\s:]+){1,}[^\s]+']

  default_scope { order(:name) }

  before_validation :normalize_attributes

  validate :has_contact_method

  validates :name, presence: true, uniqueness: true
  validates :web, format: { with: /\A#{WEB_FORMAT[0]}#{WEB_FORMAT[1]}\z/ }, allow_nil: true
  validates :meet, :address, :district, presence: true, allow_nil: true
  validates :city, presence: true
  validates :county, inclusion: { in: Ireland.counties, message: "invalid county" }
  validates :lat,  numericality: { greater_than:  51.2, less_than: 55.6, message: "must be between 51.2 and 55.6" }, allow_nil: true
  validates :long, numericality: { greater_than: -10.6, less_than: -5.3, message: "must be between -10.6 and -5.3" }, allow_nil: true
  validates :contact, presence: true, allow_nil: true
  validates :email, format: { with: /\A[^\s@]+@[^\s@]+\z/ }, allow_nil: true
  validates :phone, format: { with: /\d{3}/ }, allow_nil: true
  validates :active, inclusion: { in: [true, false] }

  def province
    Ireland.province(county)
  end

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
    matches = all
    matches = matches.where("name LIKE ?", "%#{params[:name]}%") if params[:name].present?
    matches = matches.where("city LIKE ?", "%#{params[:city]}%") if params[:city].present?
    matches = matches.where(county: params[:county]) if Ireland.county?(params[:county])
    matches = matches.where("county IN (?)", Ireland.counties(params[:province])) if Ireland.province?(params[:province])
    matches = matches.where("contact LIKE ?", "%#{params[:contact]}%") if params[:contact].present?
    case params[:active]
    when "true", nil then matches = matches.where(active: true)
    when "false"     then matches = matches.where(active: false)
    end
    paginate(matches, params, path)
  end

  private

  def has_contact_method
    if active && !contactable?
      errors[:base] << "An active club must have at least one contact method (phone, email or web)"
    end
  end

  def normalize_attributes
    # Note: 'active' is normalised automatically.
    [:name, :web, :meet, :address, :district, :city, :lat, :long, :contact, :email, :phone].each do |atr|
      self.send("#{atr}=", nil) if self.send(atr).blank?
    end
    if web.present? && web.match(/\A#{WEB_FORMAT[1]}/)
      self.web = "http://#{web}"
    end
  end
end