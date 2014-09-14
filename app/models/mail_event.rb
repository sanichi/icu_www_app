class MailEvent < ActiveRecord::Base
  include Pageable

  scope :ordered, -> { order(date: :desc, page: :asc) }

  validates :date, presence: true
  validates :page, uniqueness: { scope: :date }, numericality: { integer_only: true, greater_than: 0 }

  def self.search(params, path)
    matches = ordered
    matches = matches.where("date LIKE ?", "%#{params[:date]}%") if params[:date].present?
    paginate(matches, params, path)
  end
end
