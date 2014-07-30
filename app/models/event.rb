class Event < ActiveRecord::Base
  include Journalable
  include Normalizable
  include Pageable
  include Remarkable

  journalize %w[flyer_file_name flyer_content_type flyer_file_size name location lat long start_date end_date active category contact email phone url prize_fund note], "/events/%d"

  MIN_SIZE = 1.kilobyte
  MAX_SIZE = 3.megabytes
  CATEGORIES = %w[irish junior women foreign]
  TYPES = {
    pdf:  "application/pdf",
    doc:  "application/msword",
    docx: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    rtf:  ["application/rtf", "text/rtf"],
  }
  EXTENSIONS = /\.(#{TYPES.values.join("|")})\z/i
  CONTENT_TYPES = TYPES.values.flatten

  has_attached_file :flyer, keep_old_files: true

  belongs_to :user

  before_validation :normalize_attributes

  validates_attachment :flyer, content_type: { file_name: EXTENSIONS, content_type: CONTENT_TYPES }, size: { in: MIN_SIZE..MAX_SIZE }
  validates :name, :location, presence: true
  validates :source, inclusion: { in: Global::SOURCES }
  validates :email, format: { with: Global::EMAIL_RGX }, allow_nil: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :user_id, numericality: { integer_only: true, greater_than: 0 }
  validates :lat,  numericality: { greater_than_or_equal_to: -80.0, less_than_or_equal_to: 80.0, message: "must be between ±80.0" }, allow_nil: true
  validates :long, numericality: { greater_than_or_equal_to: -180.0, less_than_or_equal_to: 180.0, message: "must be between ±180.0" }, allow_nil: true
  validates :prize_fund, numericality: { greater_than: 0.0 }, allow_nil: true
  validates :start_date, :end_date, presence: true
  validates_date :start_date, :end_date, on_or_after: -> { Date.today }, unless: Proc.new { |e| e.source == "www1" }

  validate :valid_dates

  scope :include_player, -> { includes(user: :player) }
  scope :ordered, -> { order(:start_date, :end_date, :name) }

  def self.search(params, path)
    matches = ordered.include_player
    case params[:active]
    when "active", nil
      matches = matches.where(active: true)
    when "inactive"
      matches = matches.where(active: false)
    end
    matches = matches.where("name LIKE ?", "%#{params[:name]}%") if params[:name].present?
    matches = matches.where("location LIKE ?", "%#{params[:location]}%") if params[:location].present?
    default = Date.today
    params[:year] = default.year.to_s unless params[:year].to_s.match(/\A20\d\d\z/)
    params[:month] = "%02d" % default.month unless params[:month].to_s.match(/\A(0[1-9]|1[0-2])\z/)
    matches = matches.where("start_date >= ?", "#{params[:year]}-#{params[:month]}-01")
    matches = matches.where(category: params[:category]) if CATEGORIES.include?(params[:category])
    paginate(matches, params, path)
  end

  def note_html
    to_html(note)
  end

  def expand(opt)
    %q{<a href="/events/%d">%s</a>} % [id, opt[:name] || opt[:title] || name]
  end

  def dates
    parts = []
    if start_date.year == end_date.year
      parts.unshift start_date.year
      if start_date.month == end_date.month
        parts.unshift I18n.t("month.s#{start_date.strftime('%m')}")
        if start_date.mday == end_date.mday
          parts.unshift start_date.mday
        else
          parts.unshift "#{start_date.mday}–#{end_date.mday}"
        end
      else
        parts.unshift I18n.t("month.s#{end_date.strftime('%m')}")
        parts.unshift "#{end_date.mday}"
        parts.unshift "–"
        parts.unshift I18n.t("month.s#{start_date.strftime('%m')}")
        parts.unshift "#{start_date.mday}"
      end
    else
      parts.unshift end_date.year
      parts.unshift I18n.t("month.s#{end_date.strftime('%m')}")
      parts.unshift "#{end_date.mday}"
      parts.unshift "–"
      parts.unshift start_date.year
      parts.unshift I18n.t("month.s#{start_date.strftime('%m')}")
      parts.unshift "#{start_date.mday}"
    end
    parts.join(" ")
  end

  private

  def normalize_attributes
    normalize_blanks(:contact, :phone, :email, :url, :note)
  end

  def valid_dates
    if start_date.present? && end_date.present?
      if start_date > end_date
        errors.add(:start_date, "can't start after it ends")
      elsif end_date.year > start_date.year + 1
        errors.add(:end_date, "must end in the same or next year it starts")
      end
    end
  end
end
