class Article < ActiveRecord::Base
  extend Util::Pagination
  include Accessible
  include Expandable
  include Remarkable
  include Journalable
  journalize %w[access active author category text title year], "/article/%d"

  CATEGORIES = %w[bulletin tournament biography obituary coaching juniors general]

  belongs_to :user
  has_many :episodes, dependent: :destroy
  has_many :series, through: :episodes

  before_validation :normalize_attributes

  validates :category, inclusion: { in: CATEGORIES }
  validates :text, :title, presence: true
  validates :year, numericality: { integer_only: true, greater_than_or_equal_to: Global::MIN_YEAR }

  scope :include_player, -> { includes(user: :player) }
  scope :include_series, -> { includes(episodes: :series) }
  scope :ordered, -> { order(year: :desc, created_at: :desc) }

  def self.search(params, path, user, opt={})
    matches = ordered.include_player
    matches = matches.where("author LIKE ?", "%#{params[:author]}%") if params[:author].present?
    matches = matches.where("title LIKE ?", "%#{params[:title]}%") if params[:title].present?
    matches = matches.where("text LIKE ?", "%#{params[:text]}%") if params[:text].present?
    if params[:year].present?
      if params[:year].match(/([12]\d{3})\D+([12]\d{3})/)
        matches = matches.where("year >= ?", $1.to_i)
        matches = matches.where("year <= ?", $2.to_i)
      elsif params[:year].match(/([12]\d{3})/)
        matches = matches.where(year: $1.to_i)
      else
        matches = matches.none
      end
    end
    if params[:player_id].to_i > 0
      matches = matches.joins(user: :player)
      matches = matches.where("players.id = ?", params[:player_id].to_i)
    end
    matches = accessibility_matches(user, params[:access], matches)
    matches = matches.where(active: true) if params[:active] == "true" || params[:active].blank?
    matches = matches.where(active: false) if params[:active] == "false"
    paginate(matches, params, path, opt)
  end

  def html
    expanded = expand_all(text)
    markdown ? to_html(expanded, filter_html: false) : expanded.html_safe
  end

  def expand(opt)
    %q{<a href="/articles/%d">%s</a>} % [id, opt[:title] || title]
  end

  private

  def normalize_attributes
    %w[author].each do |atr|
      if self.send(atr).blank?
        self.send("#{atr}=", nil)
      end
    end
    if text.present?
      text.gsub!(/\r\n/, "\n")
    end
  end
end
