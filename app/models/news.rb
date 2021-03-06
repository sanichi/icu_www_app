class News < ActiveRecord::Base
  include Expandable
  include Normalizable
  include Pageable
  include Remarkable
  include Journalable

  journalize %w[active date headline summary], "/news/%d"

  belongs_to :user

  before_validation :normalize_attributes
  validates :headline, presence: true, length: { maximum: 100 }
  validates :summary, presence: true
  validates :date, date: { on_or_before: :today }
  validate :expansions

  scope :include_player, -> { includes(user: :player) }
  scope :ordered, -> { order(date: :desc, updated_at: :desc) }

  def self.search(params, path, opt={})
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
    paginate(matches, params, path, opt)
  end

  def html
    to_html(expand_all(summary), filter_html: false)
  end

  def expand(opt)
    %q{<a href="/news/%d">%s</a>} % [id, opt[:text] || headline]
  end

  def short_date
    "#{date.mon}-#{date.mday}"
  end

  private

  def normalize_attributes
    normalize_newlines(:summary)
  end

  def expansions
    if summary.present?
      begin
        expand_all(summary, true)
      rescue => e
        errors.add(:base, e.message)
      end
    end
  end
end
