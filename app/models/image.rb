class Image < ActiveRecord::Base
  extend Util::Pagination

  include Journalable
  journalize %w[data_file_name data_content_type data_file_size caption credit year], "/images/%d"

  serialize :dimensions, Hash

  TYPES = "jpe?g|gif|png"
  MAX_PIXELS = 600
  MIN_PIXELS = 30
  MIN_YEAR = 1850
  THUMB_SIZE = 100
  STYLES = { :thumbnail => "#{THUMB_SIZE}x#{THUMB_SIZE}>" }

  has_attached_file :data, styles: STYLES, keep_old_files: true

  belongs_to :user

  before_validation :normalize_attributes, :check_dimensions

  validates_attachment_content_type :data, content_type: /\Aimage\/(#{TYPES})\z/i, file_name: /\.(#{TYPES})\z/i
  validates :caption, presence: true
  validates :credit, presence: true, allow_nil: true
  validates :source, inclusion: { in: %w[www1 www2] }
  validates :year,  numericality: { integer_only: true, greater_than_or_equal_to: MIN_YEAR }
  validates :user_id, numericality: { integer_only: true, greater_than: 0 }

  validate :year_is_not_in_future

  scope :include_players, -> { includes(user: :player) }
  scope :last_updated_first, -> {  }

  def self.search(params, path)
    matches = include_players
    matches = case params[:order]
    when "updated_at"
      matches.order(updated_at: :desc)
    when "year"
      matches.order(year: :desc, id: :desc)
    else
      matches.order(id: :asc)
    end
    matches = matches.where("caption LIKE ?", "%#{params[:caption]}%") if params[:caption].present?
    matches = matches.where("credit LIKE ?", "%#{params[:credit]}%") if params[:credit].present?
    matches = matches.where(year: params[:year].to_i) if params[:year].to_i > 0
    paginate(matches, params, path)
  end

  def width(style=:original)
    dimensions[style][0]
  rescue
    THUMB_SIZE
  end

  def height(style=:original)
    dimensions[style][1]
  rescue
    THUMB_SIZE
  end

  def dimensions_description
    s = []
    if dimensions.is_a?(Hash)
      STYLES.keys.unshift(:original).each do |style|
        if dimensions[style].is_a?(Array)
          info = "#{dimensions[style][0]}×#{dimensions[style][1]}"
        else
          info = "error (not an Array)"
        end
        s.push I18n.t("image.#{style}") + ": " + info
      end
    else
      s.push "Error (not a Hash)"
    end
    s.join(", ")
  end

  def short_type
    data_content_type.split("/").last.upcase
  end

  private

  def normalize_attributes
    %w[credit].each do |atr|
      self.send("#{atr}=", nil) if self.send(atr).blank?
    end
  end

  def check_dimensions
    dimensions = {}
    STYLES.keys.push(:original).each do |style|
      tempfile = data.queued_for_write[style]
      unless tempfile.nil?
        geometry = Paperclip::Geometry.from_file(tempfile)
        width = geometry.width.to_i
        height = geometry.height.to_i
        dimensions[style] = [width, height]
        if style == :original && source != "www1"
          if width > MAX_PIXELS || height > MAX_PIXELS
            errors.add(:base, "Width and height should not exceed #{MAX_PIXELS}")
          end
          if width < MIN_PIXELS || height < MIN_PIXELS
            errors.add(:base, "Width and height should be at least #{MIN_PIXELS}")
          end
        end
      end
    end
  rescue => e
    logger.error "problem checking image dimensions: #{e.message}"
    errors.add(:base, "Problem checking image dimensions")
  ensure
    self.dimensions = dimensions unless dimensions.empty?
  end

  def year_is_not_in_future
    if year.to_i > Date.today.year
      errors.add(:year, "cannot be in the future")
    end
  end
end
