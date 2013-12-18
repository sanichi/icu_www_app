class Player < ActiveRecord::Base
  extend Util::Pagination
  extend Util::Params
  extend ICU::Util::AlternativeNames

  include Journalable
  journalize %w[first_name last_name dob gender joined fed email address home_phone mobile_phone work_phone player_title arbiter_title trainer_title note status player_id club_id], "/admin/players/%d"

  belongs_to :master, class_name: "Player", foreign_key: :player_id
  belongs_to :club
  has_many :duplicates, class_name: "Player"
  has_many :users

  GENDERS = %w[M F]
  SOURCES = %w[import archive subscription officer]
  STATUSES = %w[active inactive foreign deceased]
  PLAYER_TITLES = %w[GM IM FM CM NM WGM WIM WFM WCM]
  ARBITER_TITLES = %w[IA FA NA]
  TRAINER_TITLES = %w[FST FT FI NI DI]
  RATING_TYPES = %w[full provisional]
  
  default_scope { includes(:club) }

  before_validation :normalize_attributes, :conditional_adjustment

  validates :first_name, :last_name, presence: true
  validates :player_id, numericality: { greater_than: 0 }, allow_nil: true
  validates :club_id, numericality: { greater_than: 0 }, allow_nil: true
  validates :player_title, inclusion: { in: PLAYER_TITLES }, allow_nil:true
  validates :arbiter_title, inclusion: { in: ARBITER_TITLES }, allow_nil:true
  validates :trainer_title, inclusion: { in: TRAINER_TITLES }, allow_nil:true
  validates :email, format: { with: /\A[^\s@]+@[^\s@]+\z/ }, allow_nil: true
  validates :status, inclusion: { in: STATUSES }
  validates :source, inclusion: { in: SOURCES }
  validates :fed, format: { with: /\A[A-Z]{3}\z/ }, allow_nil: true
  validates :legacy_rating, numericality: { only_integer: true }, allow_nil: true
  validates :legacy_rating_type, inclusion: { in: RATING_TYPES }, allow_nil: true
  validates :legacy_games, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  validates_date :dob, on_or_after: "1900-01-01",
                       on_or_after_message: "too far in the past",
                       on_or_before: -> { Date.today },
                       on_or_before_message: "too far in the future",
                       allow_nil: true
  validates_date :joined, on_or_after: "1960-01-01",
                          on_or_after_message: "too far in the past",
                          on_or_before: -> { Date.today },
                          on_or_before_message: "too far in the future",
                          allow_nil: true

  validate :conditional_validations, :dob_and_joined, :duplication, :validate_phones, :validate_legacy_rating

  def name(reversed=false)
    if reversed
      "#{last_name}, #{first_name}"
    else
      "#{first_name} #{last_name}"
    end
  end

  def duplicate?
    player_id.present?
  end

  def active?
    status == "active"
  end

  def deceased?
    status == "deceased"
  end

  def age(today=Date.today)
    return unless dob
    age = today.year - dob.year
    age -= 1 if today.month < dob.month || (today.month == dob.month && today.day < dob.day)
    age
  end
  
  def federation(code=false)
    return unless fed.present?
    federation = ICU::Federation.find(fed).try(:name) || "Unknown"
    federation += " (#{fed})" if code
    federation
  end

  def titles
    titles = []
    titles << player_title if player_title
    titles << arbiter_title if arbiter_title
    titles << trainer_title if trainer_title
    titles.join(" ")
  end
  
  def phones
    %w[home mobile work].each_with_object([]) do |type, numbers|
      number = send("#{type}_phone")
      if number.present?
        numbers << I18n.t("player.phone.one_letter.#{type}") + ": " + number
      end
    end.join(", ")
  end

  def note_html
    return unless note.present?
    renderer = Redcarpet::Render::HTML.new(filter_html: true)
    markdown = Redcarpet::Markdown.new(renderer, no_intra_emphasis: true, autolink: true, strikethrough: true, underline: true)
    markdown.render(note).html_safe
  end

  def self.search(params, path, opt={})
    params[:status] = "active" unless params.has_key?(:status)
    params[:order] = "id" if params[:order].blank?
    matches = all
    matches = matches.where(id: params[:id].to_i) if params[:id].to_i > 0
    matches = matches.where(first_name_like(params[:first_name], params[:last_name])) if params[:first_name].present?
    matches = matches.where(last_name_like(params[:last_name], params[:first_name])) if params[:last_name].present?
    matches = matches.where(gender: params[:gender]) if params[:gender].present?
    matches = matches.where(status: params[:status]) if STATUSES.include?(params[:status])
    if params[:fed].present?
      case params[:fed]
      when "???"
        matches = matches.where(fed: nil)
      when "FFF"
        matches = matches.where("fed IS NOT NULL AND fed != 'IRL'")
      when "NNN"
        matches = matches.where("fed IS  NULL OR fed = 'IRL'")
      else
        matches = matches.where(fed: params[:fed])
      end
    end
    if params[:title].present?
      if params[:title] == "XX"
        matches = matches.where("player_title IS NOT NULL OR arbiter_title IS NOT NULL OR trainer_title IS NOT NULL")
      elsif params[:title] == "PP"
        matches = matches.where.not(player_title: nil)
      elsif params[:title] == "AA"
        matches = matches.where.not(arbiter_title: nil)
      elsif params[:title] == "TT"
        matches = matches.where.not(trainer_title: nil)
      elsif PLAYER_TITLES.include?(params[:title])
        matches = matches.where(player_title: params[:title])
      elsif ARBITER_TITLES.include?(params[:title])
        matches = matches.where(arbiter_title: params[:title])
      elsif TRAINER_TITLES.include?(params[:title])
        matches = matches.where(trainer_title: params[:title])
      end
    end
    if params[:status] == "duplicate"
      matches = matches.where.not(player_id: nil)
    else
      matches = matches.where(player_id: nil)
    end
    if (yob = params[:yob].to_i).to_s.match(/\A\s*(19|20)\d\d\s*\z/)
      case params[:relation]
      when "="
        matches = matches.where("dob LIKE '#{yob}%'")
      when ">"
        matches = matches.where("dob > '#{yob}-12-31'")
      when "<"
        matches = matches.where("dob < '#{yob}-01-01'")
      end
    end
    if params[:club_id].present?
      club_id = params[:club_id].to_i
      matches = matches.where(club_id: club_id > 0 ? club_id : nil)
    end
    case params[:order]
    when "last_name"
      matches = matches.order(:last_name, :first_name, :id)
    when "first_name"
      matches = matches.order(:first_name, :last_name, :id)
    when "id"
      matches = matches.order(:id)
    end
    clear_whitespace_to_reveal_placeholders(params, :id, :first_name, :last_name, :yob)
    paginate(matches, params, path, opt)
  end

  private

  def normalize_attributes
    nillable = %w[dob gender joined email address note]
    nillable+= %w[home_phone mobile_phone work_phone]
    nillable+= %w[player_title arbiter_title trainer_title]
    nillable+= %w[legacy_rating legacy_rating_type legacy_games]
    nillable.each do |atr|
      self.send("#{atr}=", nil) unless self.send(atr).present?
    end
    %w[club_id player_id].each do |atr|
      self.send("#{atr}=", nil) unless self.send(atr).to_s.to_i > 0
    end
    self.fed = ICU::Federation.find(fed).try(:code)
    name = ICU::Name.new(first_name, last_name)
    self.first_name = name.first(chars: "US-ASCII")
    self.last_name = name.last(chars: "US-ASCII")
  end

  def strict?
    if source == "import" || source == "archive"
      false
    elsif status != "active"
      false
    elsif duplicate?
      false
    else
      true
    end
  end

  def conditional_validations
    return unless strict?
    errors.add(:dob, "can't be blank when status is active") unless dob.present?
    errors.add(:joined, "can't be blank when status is active") unless joined.present?
    errors.add(:gender, "can't be blank when status is active") unless gender.present?
    errors.add(:gender, "invalid") if gender.present? && !GENDERS.include?(gender)
  end

  def dob_and_joined
    return unless dob.present? && joined.present? && errors[:joined].empty?
    errors.add(:joined, "must be after born") unless joined.to_s > dob.to_s
  end

  def duplication
    return if source == "import"
    return unless player_id.present?
    duplicate = player_id.to_i
    error = nil
    if duplicate == id
      error = "can't duplicate self"
    else
      player = Player.find_by(id: duplicate)
      if !player
        error = "can't duplicate a non-existent record"
      elsif player.duplicate?
        error = "can't duplicate a duplicate"
      end
    end
    errors.add(:player_id, error) if error
  end

  def conditional_adjustment
    if active? && duplicate?
      self.status = "inactive"
    end
  end
  
  def validate_phones
    mob = {}
    err = 0

    # Canonicalize or reject using the Phone class.
    %w[home mobile work].each do |type|
      atr = "#{type}_phone"
      val = self.send(atr)
      unless val.nil?
        phone = Phone.new(val)
        if phone.blank?
          self.send("#{atr}=", nil)
        elsif phone.parsed?
          self.send("#{atr}=", phone.canonical)
          mob[atr] = phone.mobile?
        else
          errors.add(atr.to_sym, "invalid")
          err += 1
        end
      end
    end

    # If possible, make sure the mobile phone is in the right database column.
    if err == 0 && !mob["mobile_phone"]
      mobile = %w[home work].map{ |type| "#{type}_phone" }.find{ |atr| mob[atr] }
      if mobile
        tmp = self.mobile_phone
        self.mobile_phone = self.send(mobile)
        self.send("#{mobile}=", tmp)
      end
    end
  end
  
  # Either all legacy rating attributes are nil or none are.
  def validate_legacy_rating
    atrs = %w[rating rating_type games]
    nil_count = atrs.reduce(0) do |count, atr|
      count += self.send("legacy_#{atr}").nil? ? 1 : 0
    end
    return if nil_count == 0 || nil_count == atrs.size
    atrs.map{ |atr| "legacy_#{atr}".to_sym }.each do |fatt|
      errors.add(fatt, "need all legacy rating data or none") if self.send(fatt).nil?
    end
  end
end
