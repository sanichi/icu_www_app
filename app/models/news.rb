class News < ActiveRecord::Base
  include Pageable
  include Expandable
  include Remarkable
  include Journalable
  journalize %w[active date headline summary], "/news/%d"

  belongs_to :user

  before_validation :normalize_attributes
  validates :date, :headline, :summary, presence: true
  validates_date :date, on_or_before: -> { Date.today }
  validate :expansions

  scope :include_player, -> { includes(user: :player) }
  scope :ordered, -> { order(date: :desc, updated_at: :desc) }

  def self.search(params, path, user)
    matches = ordered.include_player
    matches = matches.where("headline LIKE ?", "%#{params[:headline]}%") if params[:headline].present?
    matches = matches.where("summary LIKE ?", "%#{params[:summary]}%") if params[:summary].present?
    matches = matches.where("date LIKE ?", "%#{params[:date]}%") if params[:date].present?
    if params[:player_id].to_i > 0
      matches = matches.joins(user: :player)
      matches = matches.where("players.id = ?", params[:player_id].to_i)
    end
    matches = matches.where(active: true) if params[:active] == "true"
    matches = matches.where(active: false) if params[:active] == "false"
    paginate(matches, params, path)
  end

  def html
    to_html(expand_all(summary), filter_html: false)
  end

  def expand(opt)
    %q{<a href="/news/%d">%s</a>} % [id, opt[:text] || headline]
  end

  private

  def normalize_attributes
    if summary.present?
      summary.gsub!(/\r\n/, "\n")
    end
  end

  def expansions
    if summary.present?
      begin
        expand_all(summary)
      rescue => e
        errors.add(:base, e.message)
      end
    end
  end
end
