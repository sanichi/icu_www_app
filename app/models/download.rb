class Download < ActiveRecord::Base
  include Accessible
  include Journalable
  include Pageable

  journalize %w[access data_file_name data_content_type data_file_size description year access], "/admin/downloads/%d"

  attr_accessor :dir_to_remove

  MIN_SIZE = 500
  MAX_SIZE = 5.megabytes
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

  before_save :correct_plain_text
  before_destroy :remember_directory

  # Note: need to add the callbacks Paperclip registers in the right order.
  has_attached_file :data, url: "/system/:class/:id_partition/:hash.:extension", hash_secret: Rails.application.secrets.paperclip

  after_save :manage_unobfuscated_version
  after_destroy :clean_up_directory

  validates_attachment :data, content_type: { file_name: EXTENSIONS, content_type: CONTENT_TYPES }, size: { in: MIN_SIZE..MAX_SIZE }
  validates :data, :description, presence: true
  validates :year,  numericality: { integer_only: true, greater_than_or_equal_to: Global::MIN_YEAR }
  validates :user_id, numericality: { integer_only: true, greater_than: 0 }
  validates :www1_path, length: { maximum: 128 }, allow_nil: true

  validate :year_is_not_in_future, :year_in_description

  scope :include_player, -> { includes(user: :player) }
  scope :ordered, -> { order(year: :desc, description: :asc) }

  def self.search(params, path, user)
    matches = ordered.include_player
    matches = matches.where("description LIKE ?", "%#{params[:description]}%") if params[:description].present?
    matches = matches.where(year: params[:year].to_i) if params[:year].to_i > 0
    matches = matches.where(data_content_type: TYPES[params[:type].to_sym]) if params[:type].present? && TYPES.include?(params[:type].to_sym)
    matches = accessibility_matches(user, params[:access], matches)
    paginate(matches, params, path)
  end

  def url
    if access == "all"
      unobfuscate(data.url)
    else
      data.url
    end
  end

  def expand(opt)
    %q{<a href="/downloads/%d">%s</a>} % [id, opt[:text] || "download"]
  end

  private

  def unobfuscate(path_or_url)
    path_or_url.sub(Pathname.new(data.path).basename.to_s, data_file_name)
  end

  def manage_unobfuscated_version
    obfuscated = data.path.to_s
    unobscured = unobfuscate(obfuscated)
    if access == "all"
      FileUtils.cp(obfuscated, unobscured, preserve: true)
    else
      FileUtils.rm(unobscured, force: true)
    end
  rescue => e
    Failure.log("UnobfuscatedDownloadError", exception: e.class.to_s, message: e.message, id: id, access: access)
  end

  def remember_directory
    self.dir_to_remove = Pathname.new(data.path).dirname.to_s
  end

  def clean_up_directory
    # We're going to remove a directory recursively so be careful here.
    # The check is based on the fact that we're using Paperclip's ID partition.
    raise "no directory to cleanup" if dir_to_remove.blank?
    if dir_to_remove.match(/downloads\/\d{3}\/\d{3}\/\d{3}\z/)
      FileUtils.remove_dir(dir_to_remove, force: true)
    else
      raise "#{dir_to_remove} doesn't match the expected pattern"
    end
    raise "#{dir_to_remove} still exists" if File.exist?(dir_to_remove)
  rescue => e
    Failure.log("CleanupDownloadError", exception: e.class.to_s, message: e.message, id: id)
  end

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
    # No point checking if there's no year or description or if the description doesn't contain a year.
    return unless year.present? && description.present? && description.match(/(?<!#)\b(?:18i|19|20)\d\d\b/)

    # Scan for patterns like "2013", "2013-14" and "2013/2014" (but not if preceeded by '#' to indicate a non-year).
    years_or_seasons = description.scan(/(?<!#)\b(?:(?:18|19|20)\d\d)(?:\s*[-\/]\s*(?:(?:18|19|20)?\d\d))?\b/)

    # Turn these to (numerical) years.
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
