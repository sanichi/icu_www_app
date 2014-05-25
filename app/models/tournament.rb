class Tournament < ActiveRecord::Base
  extend Util::Pagination

  include Journalable
  journalize %w[active category city details format name year], "/tournaments/%d"

  CATEGORIES = %w[championship open junior section international veteran blind grand_prix]
  FORMATS = %w[swiss rr swiss_teams rr_teams knockout match schev simul grand_prix]

  scope :ordered, -> { order(year: :desc, name: :asc) }

  before_validation :normalize_attributes

  validates :active, inclusion: { in: [true, false] }
  validates :category, inclusion: { in: CATEGORIES }
  validates :details, presence: true
  validates :format, inclusion: { in: FORMATS }
  validates :name, presence: true, uniqueness: { scope: :year, message: "should happen once per year" }
  validates :year, numericality: { integer_only: true, greater_than_or_equal: Global::MIN_YEAR }

  validate :no_markup_in_details

  def self.search(params, path)
    matches = ordered
    matches = matches.where(active: true) if params[:active] == "true" || params[:active].blank?
    matches = matches.where(active: false) if params[:active] == "false"
    matches = matches.where(category: params[:category]) if params[:category].present?
    matches = matches.where("city LIKE ?", "%#{params[:city]}%") if params[:city].present?
    matches = matches.where(format: params[:format]) if params[:format].present?
    matches = matches.where("name LIKE ?", "%#{params[:name]}%") if params[:name].present?
    matches = matches.where(year: params[:year].to_i) if params[:year].to_i > 0
    paginate(matches, params, path)
  end

  private

  def normalize_attributes
    [:city].each do |atr|
      self.send("#{atr}=", nil) if self.send(atr).blank?
    end
  end

  def no_markup_in_details
    if details.present? && details.match(/</)
      errors.add(:base, "No makup allowed in details (use ICU markup)")
    end
  end
end
