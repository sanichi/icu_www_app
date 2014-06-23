class Image < ActiveRecord::Base
  include Journalable
  include Pageable

  journalize %w[data_file_name data_content_type data_file_size caption credit year], "/images/%d"

  serialize :dimensions, Hash

  TYPES = "jpe?g|gif|png"
  MAX_PIXELS = 600
  MIN_PIXELS = 30
  THUMB_SIZE = 100
  STYLES = { :thumbnail => "#{THUMB_SIZE}x#{THUMB_SIZE}>" }

  has_attached_file :data, styles: STYLES, keep_old_files: true

  belongs_to :user

  before_validation :normalize_attributes, :check_dimensions

  validates_attachment :data, content_type: { content_type: /\Aimage\/(#{TYPES})\z/, file_name: /\.(#{TYPES})\z/i }
  validates :data, presence: true
  validates :caption, presence: true
  validates :credit, presence: true, allow_nil: true
  validates :source, inclusion: { in: Global::SOURCES }
  validates :year, numericality: { integer_only: true, greater_than_or_equal_to: Global::MIN_YEAR }
  validates :user_id, numericality: { integer_only: true, greater_than: 0 }

  validate :year_is_not_in_future

  scope :include_player, -> { includes(user: :player) }

  def self.search(params, path)
    matches = include_player
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
    data_content_type.to_s.split("/").last.to_s.upcase
  end

  def expand(opt)
    if opt[:type] == "IML"
      %q{<a href="/images/%d">%s</a>} % [id, opt[:text] || "image"]
    elsif opt[:type] == "IMG"
      width, height = resize(opt)
      alt = (opt[:alt] || caption).gsub(/"/, '\"')
      margin = opt[:margin] || "yes"
      atrs = []
      atrs.push %Q/src="#{data.url}"/
      atrs.push %Q/width="#{width}"/
      atrs.push %Q/height="#{height}"/
      if opt[:align] == "left" || opt[:align].blank?
        atrs.push 'class="float-left%s"' % (margin == "yes" ? " right-margin" : "")
      end
      if opt[:align] == "right"
        atrs.push 'class="float-right%s"' % (margin == "yes" ? " left-margin" : "")
      end
      atrs.push %Q/alt="#{alt}"/
      cl, cr = opt[:align] == "center" ? ["<center>", "</center>"] : ["", ""]
      "#{cl}<img #{atrs.join(" ")}>#{cr}"
    else
      raise "invalid expandable type (#{opt[:type]}) for Image"
    end
  end

  private

  def normalize_attributes
    %w[caption credit].each do |atr|
      if self.send(atr).present?
        self.send(atr).markoff!.trim!
      else
        self.send("#{atr}=", nil)
      end
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

  def resize(opt)
    width = opt[:width].to_i
    height = opt[:height].to_i
    if width <= 0 && height <= 0
      width = self.width
      height = self.height
    elsif width <= 0
      width = ((height.to_f / self.height) * self.width).ceil
    elsif height <= 0
      height = ((width.to_f / self.width) * self.height).ceil
    end
    [width, height]
  end
end
