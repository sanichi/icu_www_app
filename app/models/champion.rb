class Champion < ActiveRecord::Base
  include Journalable
  include Normalizable
  include Pageable

  journalize %w[category notes winners year], "/champions/%d"

  CATEGORIES = %w[open women]

  scope :ordered, -> { order(year: :desc, category: :asc) }

  before_validation :normalize_attributes

  validates :category, inclusion: { in: CATEGORIES }, uniqueness: { scope: :year, message: "one category per year" }
  validates :winners, presence: true, length: { maximum: 256 }
  validates :notes, length: { maximum: 256 }, allow_nil: true
  validates :year, numericality: { integer_only: true, greater_than_or_equal_to: Global::MIN_YEAR, less_than_or_equal_to: Date.today.year }

  def self.search(params, path)
    matches = ordered
    matches = matches.where(category: params[:category]) if CATEGORIES.include?(params[:category])
    matches = matches.where("winners LIKE ?", "%#{params[:winners]}%") if params[:winners].present?
    matches = matches.where("year LIKE ?", "%#{params[:year]}%") if params[:year].present? && params[:year].match(/\A(18|19|20)/)
    paginate(matches, params, path)
  end

  private

  def normalize_attributes
    normalize_blanks(:notes)
  end
end
