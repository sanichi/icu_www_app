class Player < ActiveRecord::Base
  extend Util::Params
  extend ICU::Util::AlternativeNames
  include Journalable
  include Normalizable
  include Pageable
  include Remarkable

  journalize %w[
    first_name last_name dob gender fed email address home_phone mobile_phone work_phone
    joined player_title arbiter_title trainer_title note status player_id club_id privacy
  ], "/admin/players/%d"

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
  PRIVACIES = %w[home_phone mobile_phone work_phone]

  scope :include_clubs, -> { includes(:club) }
  scope :non_duplicates, -> { where("player_id IS NULL") }

  before_validation :normalize_attributes, :conditional_adjustment, :canonicalize_privacy

  validates :first_name, :last_name, presence: true
  validates :player_id, numericality: { greater_than: 0 }, allow_nil: true
  validates :club_id, numericality: { greater_than: 0 }, allow_nil: true
  validates :player_title, inclusion: { in: PLAYER_TITLES }, allow_nil:true
  validates :arbiter_title, inclusion: { in: ARBITER_TITLES }, allow_nil:true
  validates :trainer_title, inclusion: { in: TRAINER_TITLES }, allow_nil:true
  validates :email, email: true, allow_nil: true
  validates :status, inclusion: { in: STATUSES }
  validates :source, inclusion: { in: SOURCES }
  validates :fed, format: { with: /\A[A-Z]{3}\z/ }, allow_nil: true
  validates :latest_rating, numericality: { only_integer: true }, allow_nil: true
  validates :legacy_rating, numericality: { only_integer: true }, allow_nil: true
  validates :legacy_rating_type, inclusion: { in: RATING_TYPES }, allow_nil: true
  validates :legacy_games, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :privacy, format: { with: /\A(#{PRIVACIES.join('|')})( (#{PRIVACIES.join('|')}))*\z/ }, allow_nil: true
  validates :dob, date: { on_or_after: Global::MIN_DOB, on_or_before: :today }, allow_nil: true
  validates :joined, date: { on_or_after: Global::MIN_JOINED, on_or_before: :today }, allow_nil: true

  validate :conditional_validations, :dob_and_joined, :duplication, :validate_phones, :validate_legacy_rating

  def name(reversed: false, id: false)
    names = []
    names << (reversed ? "#{last_name}, #{first_name}" : "#{first_name} #{last_name}")
    names << "(#{self.id || I18n.t('new')})" if id
    names.join(" ")
  end

  def initials
    name.gsub(/[^A-Z]/, "")
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

  def age(ref=Date.today)
    return unless dob
    age = ref.year - dob.year
    age -= 1 if ref.month < dob.month || (ref.month == dob.month && ref.day < dob.day)
    age
  end

  def age_over?(max, ref=Date.today)
    return false unless dob
    age(ref) > max
  end

  def age_under?(min, ref=Date.today)
    return false unless dob
    age(ref) < min
  end

  def too_strong?(max)
    return false unless latest_rating || legacy_rating
    (latest_rating || legacy_rating) > max
  end

  def too_weak?(min)
    return false unless latest_rating || legacy_rating
    (latest_rating || legacy_rating) < min
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

  def phones(filter: false)
    %w[home mobile work].each_with_object([]) do |type, numbers|
      atr = "#{type}_phone"
      number = send(atr)
      if number.present? && (!filter || privacy.blank? || !privacy.include?(atr))
        numbers << I18n.t("player.phone.one_letter.#{type}") + ": " + number
      end
    end.join(", ")
  end

  def formatted_privacy
    privacy.to_s.scan(/\w+/).map do |p|
      p.match(/\A([a-z]+)_phone\z/) ? I18n.t("player.phone.#{$1}") : p
    end.join(", ")
  end

  def note_html
    to_html(note)
  end

  def self.search(params, path, opt={})
    params[:status] = "active" unless params.has_key?(:status)
    params[:duplicate] = "false" unless params.has_key?(:duplicate)
    params[:order] = "id" if params[:order].blank?
    matches = include_clubs
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
    if params[:duplicate] == "true"
      matches = matches.where.not(player_id: nil)
    elsif params[:duplicate] == "false"
      matches = matches.where(player_id: nil)
    end
    if (1900..2099).include?(yob = params[:yob].to_i)
      case params[:yob_relation]
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

  def self.search_subscribers(params, path)
    matches = include_clubs.order(:last_name, :first_name)
    if params[:season].present? && params[:season].to_s.match(/\A20\d\d-\d\d\z/)
      matches = matches.where(search_subscribers_sql, "%#{params[:season]}")
      matches = matches.where(first_name_like(params[:first_name], params[:last_name])) if params[:first_name].present?
      matches = matches.where(last_name_like(params[:last_name], params[:first_name])) if params[:last_name].present?
      if params[:club_id].present?
        club_id = params[:club_id].to_i
        matches = matches.where(club_id: club_id > 0 ? club_id : nil)
      end
    else
      matches = matches.none
    end
    paginate(matches, params, path)
  end

  def self.life_members
    matches = include_clubs.order(:last_name, :first_name).where.not(status: "deceased")
    matches = matches.where(life_members_sql)
    matches
  end

  def self.search_subscribers_sql
    <<SQL
EXISTS(SELECT * FROM items WHERE
  type        = 'Item::Subscription' AND
  status      = 'paid' AND
  player_id   = players.id AND
  description LIKE ?
)
SQL
  end

  def self.life_members_sql
    <<SQL
EXISTS(SELECT * FROM items WHERE
  type        = 'Item::Subscription' AND
  status      = 'paid' AND
  player_id   = players.id AND
  description LIKE 'Lifetime%'
)
SQL
  end

  private

  def normalize_attributes
    nillable = %i[dob gender joined email address note]
    nillable+= %i[home_phone mobile_phone work_phone]
    nillable+= %i[player_title arbiter_title trainer_title]
    nillable+= %i[legacy_rating legacy_rating_type legacy_games latest_rating]
    normalize_blanks(*nillable)
    %w[club_id player_id].each do |atr|
      self.send("#{atr}=", nil) unless self.send(atr).to_s.to_i > 0
    end
    self.fed = ICU::Federation.find(fed).try(:code)
    name = ICU::Name.new(first_name, last_name)
    self.first_name = name.first(chars: "US-ASCII")
    self.last_name = name.last(chars: "US-ASCII")
  end

  def canonicalize_privacy
    if privacy.present?
      self.privacy = privacy.scan(/\w+/) unless privacy.is_a?(Array)
      self.privacy = privacy.select{ |p| PRIVACIES.include?(p) }.sort.join(" ")
    end
    self.privacy = nil if privacy.blank?
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
