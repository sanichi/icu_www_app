class NewPlayer
  include ActiveModel::Model # see https://github.com/rails/rails/blob/master/activemodel/lib/active_model/model.rb

  ATTRS = %i[first_name last_name dob gender fed email joined club_id]
  attr_accessor *ATTRS

  validates :first_name, :last_name, presence: true
  validates :fed, format: { with: /\A[A-Z]{3}\z/ }
  validates :gender, inclusion: { in: Player::GENDERS }
  validates :club_id, numericality: { greater_than: 0 }, allow_nil: true
  validates :email, email: true, allow_nil: true

  validates_date :dob, after: "1900-01-01", on_or_before: -> { Date.today }
  validates_date :joined, after: "2014-01-01", on_or_before: -> { Date.today }

  validate :no_db_duplicates

  def initialize(attributes={})
    attributes.each do |name, value|
      public_send("#{name}=", value)
    end
    canonicalize
  end

  def icu_name
    @icu_name ||= ICU::Name.new(first_name, last_name)
  end

  def name
    "#{first_name} #{last_name} (#{I18n.t('new')})"
  end

  def self.from_json(json)
    new JSON.parse(json) rescue nil
  end

  def to_json
    to_hash.to_json
  end

  def to_player
    Player.new(to_hash.merge(status: "active", source: "subscription"))
  end

  def ==(other)
    return false unless other.is_a?(NewPlayer) || other.is_a?(Player)
    dob == other.dob && icu_name.match(other.first_name, other.last_name)
  end

  private

  def to_hash
    ATTRS.each_with_object({}){ |atr, hash| hash[atr] = send(atr) }
  end

  def canonicalize
    if first_name.present? && last_name.present?
      self.first_name = icu_name.first
      self.last_name = icu_name.last
    end
    self.email = email.present? ? email.gsub(/\s+/, "") : nil
    self.club_id = nil unless club_id.to_i > 0
    self.dob = Date.parse(dob) rescue nil unless dob.is_a?(Date)
    self.joined = Date.parse(joined) rescue nil unless joined.is_a?(Date)
  end

  def no_db_duplicates
    if dob.present? && first_name.present? && last_name.present?
      duplicates = Player.non_duplicates.where(dob: dob).select { |player| self == player }
      if duplicates.any?
        errors[:base] << I18n.t("item.error.subscription.new_player_duplicate.db", matches: duplicates.map{ |p| p.name(id: true) }.join(", "))
      end
    end
  end
end
