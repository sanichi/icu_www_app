class Player < ActiveRecord::Base
  extend Util::Pagination
  extend Util::Params

  include Journalable
  journalize %w[first_name last_name dob gender joined status player_id], "/admin/players/%d"

  belongs_to :master, class_name: "Player", foreign_key: :player_id
  has_many   :duplicates, class_name: "Player"

  GENDERS = %w[M F]
  SOURCES = %w[import archive subscription officer]
  STATUSES = %w[active inactive foreign deceased]

  before_validation :normalize_attributes, :conditional_adjustment

  validates :first_name, :last_name, presence: true
  validates :player_id, numericality: { greater_than: 0 }, allow_nil: true
  validates :status, inclusion: { in: STATUSES }
  validates :source, inclusion: { in: SOURCES }

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

  validate :conditional_validations, :dob_and_joined, :duplication

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

  def self.search(params, path)
    params[:status] = "active" if params[:status].blank?
    params[:order] = "id" if params[:oreder].blank?
    matches = all
    matches = matches.where(id: params[:id].to_i) if params[:id].to_i > 0
    matches = matches.where("first_name LIKE ?", "%#{params[:first_name]}%") if params[:first_name].present?
    matches = matches.where("last_name LIKE ?", "%#{params[:last_name]}%") if params[:last_name].present?
    matches = matches.where(gender: params[:gender]) if params[:gender].present?
    matches = matches.where(status: params[:status]) if STATUSES.include?(params[:status])
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
    case params[:order]
    when "last_name"
      matches = matches.order(:last_name, :first_name, :id)
    when "first_name"
      matches = matches.order(:first_name, :last_name, :id)
    when "id"
      matches = matches.order(:id)
    end
    clear_whitespace_to_reveal_placeholders(params, :id, :first_name, :last_name, :yob)
    paginate(matches, params, path)
  end

  private

  def normalize_attributes
    %w[player_id gender dob joined].each do |atr|
      self.send("#{atr}=", nil) if self.send(atr).blank?
    end
    name = ICU::Name.new(first_name, last_name)
    self.first_name = name.first
    self.last_name = name.last
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
end
