class Article < ActiveRecord::Base
  extend Util::Pagination
  include Accessible
  include Remarkable
  include Journalable
  journalize %w[access active author category text title], "/article/%d"

  CATEGORIES = %w[bulletin tournament biography obituary coaching juniors general]

  belongs_to :user
  has_many :episodes, dependent: :destroy
  has_many :series, through: :episodes

  before_validation :normalize_attributes

  validates :category, inclusion: { in: CATEGORIES }
  validates :text, :title, presence: true

  scope :include_player, -> { includes(user: :player) }
  scope :include_series, -> { includes(episodes: :series) }
  scope :ordered, -> { order(created_at: :desc) }

  def self.search(params, path, user, opt={})
    matches = ordered.include_player
    matches = matches.where("author LIKE ?", "%#{params[:author]}%") if params[:author].present?
    matches = matches.where("title LIKE ?", "%#{params[:title]}%") if params[:title].present?
    matches = matches.where("text LIKE ?", "%#{params[:text]}%") if params[:text].present?
    matches = accessibility_matches(user, params[:access], matches)
    matches = matches.where(active: true) if params[:active] == "true" || params[:active].blank?
    matches = matches.where(active: false) if params[:active] == "false"
    paginate(matches, params, path, opt)
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
