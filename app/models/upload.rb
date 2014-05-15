class Upload < ActiveRecord::Base
  extend Util::Pagination

  include Journalable
  journalize %w[data_file_name data_content_type data_file_size description year access], "/uploads/%d"

  ACCESSIBILITIES = %w[all members editors admins]
  EXTS = /\.(doc|docx|pdf|pgn)\z/i
  MIN_SIZE = 1.kilobyte
  MIN_YEAR = 1850
  MAX_SIZE = 3.megabytes
  TYPES = /\Aapplication\/(
    msword                                                          | # DOC
    vnd\.openxmlformats-officedocument\.wordprocessingml\.document  | # DOCX
    pdf                                                             | # PDF
    x-chess-pgn                                                       # PGN
  )\z/x

  has_attached_file :data, keep_old_files: true

  belongs_to :user

  validates_attachment :data, content_type: { file_name: EXTS, content_type: TYPES }, size: { in: MIN_SIZE..MAX_SIZE }
  validates :data, :description, presence: true
  validates :source, inclusion: { in: ::Global::SOURCES }
  validates :access, inclusion: { in: ACCESSIBILITIES }
  validates :year,  numericality: { integer_only: true, greater_than_or_equal_to: MIN_YEAR }
  validates :user_id, numericality: { integer_only: true, greater_than: 0 }

  validate :year_is_not_in_future

  scope :include_players, -> { includes(user: :player) }
  scope :ordered, -> { order(year: :desc, description: :asc) }

  def self.search(params, path, user)
    matches = ordered.include_players
    matches = matches.where("description LIKE ?", "%#{params[:description]}%") if params[:description].present?
    matches = matches.where(year: params[:year].to_i) if params[:year].to_i > 0
    options = accessibilities_for(user)
    if params[:access].present?
      if options.include?(params[:access])
        matches = matches.where(access: params[:access])
      else
        matches = matches.none
      end
    else
      matches = matches.where(access: options)
    end
    paginate(matches, params, path)
  end

  def self.accessibilities_for(user)
    max = case
      when user.admin?  then 3
      when user.editor? then 2
      when user.member? then 1
      else 0
    end
    ACCESSIBILITIES[0..max]
  end

  private

  def year_is_not_in_future
    if year.to_i > Date.today.year
      errors.add(:year, "cannot be in the future")
    end
  end
end
