class Upload < ActiveRecord::Base
  extend Util::Pagination

  include Journalable
  journalize %w[data_file_name data_content_type data_file_size description year access], "/uploads/%d"

  ACCESSIBILITIES = %w[all members editors admins]
  MIN_SIZE = 500
  MIN_YEAR = 1850
  MAX_SIZE = 4.megabytes
  TYPES = {
    csv:  "text/csv",
    doc:  "application/msword",
    docx: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    pdf:  "application/pdf",
    pgn:  "application/x-chess-pgn",
    txt:  "text/plain",
    wav:  "audio/x-wav",
    xls:  ["application/vnd.ms-excel", "application/vnd.ms-office"],
    xlsx: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  }
  EXTENSIONS = /\.(#{TYPES.values.join("|")})\z/i
  CONTENT_TYPES = TYPES.values.flatten

  belongs_to :user

  has_attached_file :data, url: "/system/:class/:id_partition/:hash.:extension", hash_secret: Rails.application.secrets.paperclip

  validates_attachment :data, content_type: { file_name: EXTENSIONS, content_type: CONTENT_TYPES }, size: { in: MIN_SIZE..MAX_SIZE }
  validates :data, :description, presence: true
  validates :access, inclusion: { in: ACCESSIBILITIES }
  validates :year,  numericality: { integer_only: true, greater_than_or_equal_to: MIN_YEAR }
  validates :user_id, numericality: { integer_only: true, greater_than: 0 }
  validates :www1_path, length: { maximum: 128 }, allow_nil: true

  validate :year_is_not_in_future, :year_in_description

  before_save :correct_plain_text

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
    matches = matches.where(data_content_type: TYPES[params[:type].to_sym]) if params[:type].present? && TYPES.include?(params[:type].to_sym)
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

  def correct_plain_text
    if data_content_type == "text/plain" && data_file_name.present?
      %i[csv pgn].each do |ext|
        if data_file_name.match(/\.#{ext}\z/)
          self.data_content_type = TYPES[ext]
        end
      end
    end
  end

  def year_is_not_in_future
    if year.to_i > Date.today.year
      errors.add(:year, "cannot be in the future")
    end
  end

  def year_in_description
    # No point check if there's no year or description or if the description doesn't contain a year.
    return unless year.present? && description.present? && description.match(/(?<!#)\b(?:18|19|20)\d\d\b/)

    # Scan for patterns like "2013", "2013-14" and "2013/2014"
    years_or_seasons = description.scan(/(?<!#)\b(?:(?:18|19|20)\d\d)(?:\s*[-\/]\s*(?:(?:18|19|20)?\d\d))?\b/)

    # Turn these to years.
    years = []
    years_or_seasons.each do |yos|
      case yos
      when /\A\d{4}\z/
        years.push(yos.to_i)
      when /\A(\d{4}).(\d{4})\z/
        years.push($1.to_i)
        years.push($2.to_i)
      when /\A(\d{4}).(\d{2})\z/
        years.push($1.to_i)
        years.push(($1[0,2] + $2).to_i)
      end

      # Remove 1800, 1900 and 2000 as they may be grading limits rather than years.
      years.reject! { |y| y % 100 == 0 }

      # Check that at least one of the years from the description matches the actual year.
      unless years.empty? || years.include?(year)
        errors.add(:description, "conflicts with year")
      end
    end
  end
end