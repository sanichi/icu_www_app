class EntryFee < ActiveRecord::Base
  extend Util::Pagination
  include Journalable
  journalize %w[
    event_name event_start event_end amount
    discounted_amount discount_deadline
    sale_start sale_end player_id
    age_ref_date min_age max_age
  ], "/admin/entry_fees/%d"

  has_many :entries
  belongs_to :player, -> { includes :users }

  before_validation :normalize_attributes, :default_attributes

  validates :event_name, presence: true, uniqueness: { scope: :year_or_season, message: "no more than one per year/season" }
  validates :amount, numericality: { greater_than: 0.0 }
  validates :amount, numericality: { greater_than: 0.0 }, allow_nil: true
  validates :discounted_amount, presence: true, if: Proc.new { |f| f.discount_deadline.present? }
  validates :discount_deadline, presence: true, if: Proc.new { |f| f.discounted_amount.present? }
  validates :event_start, :event_end, :sale_start, :sale_end, presence: true
  validates :min_rating, :max_rating, numericality: { only_integer: true, greater_than: 0, less_than: 3000 }, allow_nil: true
  validates :min_age, :max_age, numericality: { only_integer: true, greater_than: 0, less_than: 100 }, allow_nil: true
  validate :check_dates, :check_discount, :check_contact, :check_website, :check_rating_limits, :check_age_constraints

  scope :ordered, -> { order(event_start: :desc, event_name: :asc) }
  scope :on_sale, -> { where("sale_start <= ?", Date.today).where("sale_end >= ?", Date.today) }

  def self.search(params, path)
    matches = ordered
    paginate(matches, params, path, per_page: 10)
  end

  def description
    "#{event_name} #{year_or_season}"
  end

  def cost
    discountable? ? discounted_amount : amount
  end

  def discountable?
    discounted_amount && discount_deadline && Date.today <= discount_deadline
  end

  def rollover_params
    params = { event_name: event_name, event_website: event_website, amount: amount, discounted_amount: discounted_amount, player_id: player_id }
    %w[event_start event_end sale_start sale_end discount_deadline].map(&:to_sym).each do |atr|
      val = self.send(atr)
      params[atr] = val.present? ? val.years_since(1) : nil
    end
    params
  end

  def event_host
    return unless event_website
    uri = URI.parse(event_website)
    uri.host
  end

  def deletable?
    entries.count == 0
  end

  private

  def normalize_attributes
    %w[discount_deadline discounted_amount event_website].each do |atr|
      self.send("#{atr}=", nil) if self.send(atr).blank?
    end
    %w[player_id min_rating max_rating min_age max_age].each do |atr|
      self.send("#{atr}=", nil) unless self.send(atr).to_i > 0
    end
    if event_website && event_website.match(/\A[-\w]+(\.[-\w]+)*(:\d+)?\z/)
      self.event_website = "http://#{event_website}"
    end
  end

  def default_attributes
    if event_start.present?
      self.sale_end = event_start.days_ago(1) if sale_end.blank?
      self.sale_start = event_start.months_ago(3) if sale_start.blank?
    end
    if event_start.present? && event_end.present?
      if event_start.year == event_end.year
        self.year_or_season = event_start.year.to_s
      else
        season = Season.new("#{event_start.year} #{event_end.year}")
        self.year_or_season = season.to_s unless season.error
      end
    end
  end

  def check_dates
    if event_start.present? && event_end.present?
      if event_start > event_end
        errors.add(:event_start, "can't start after it ends")
      elsif event_end.year > event_start.year + 1
        errors.add(:event_end, "must end in the same or next year it starts")
      end
    end
    if sale_end.present? && event_start.present? && sale_end > event_start
      errors.add(:sale_end, "should end on or before the event begins")
    end
    if sale_start.present? && sale_end.present? && sale_start > sale_end
      errors.add(:sale_start, "can't start after it ends")
    end
    if discount_deadline.present? && discounted_amount.present?
      if sale_start.present? && discount_deadline <= sale_start
        errors.add(:discount_deadline, "should be after sale starts")
      end
      if sale_end.present? && discount_deadline >= sale_end
        errors.add(:discount_deadline, "should be before sale ends")
      end
    end
  end

  def check_discount
    if discounted_amount.present? && discounted_amount >= amount
      errors.add(:discounted_amount, "discounted amount should be less than normal cost")
    end
  end

  def check_contact
    return if player_id.nil?
    if player.blank?
      errors[:base] << "Invalid contact"
    elsif player.email.blank?
      errors[:base] << "Contact has no email address"
    elsif player.users.empty?
      errors[:base] << "Contact has no login to this website"
    elsif player.users.select{ |u| u.expires_on > Date.today }.empty?
      errors[:base] << "Contact is not a current member of the ICU"
    end
  end

  def check_website
    return if event_website.nil?
    uri = URI.parse(event_website)
    raise "invalid web address" unless uri.try(:scheme).try(:match, /\Ahttps?\z/) && uri.host.present? && uri.port.present?
    req = Net::HTTP.new(uri.host, uri.port)
    req.read_timeout = 10
    res = req.start { |http| http.head(uri.path.blank? ? "/" : uri.path) }
    raise "got bad response for this web address" unless res.kind_of?(Net::HTTPSuccess)
  rescue => e
    errors.add(:event_website, e.message)
  end

  def check_rating_limits
    return unless min_rating && max_rating
    if min_rating > max_rating
      errors[:base] << "Rating minimum is greater than maximum"
    elsif min_rating + 100 > max_rating
      errors[:base] << "Rating limits are too close"
    end
  end

  def check_age_constraints
    if min_age || max_age
      unless age_ref_date.present?
        %w[min_age max_age].each { |m| errors[m.to_sym] << "Age reference date required" if self.send(m) }
      end
    end
    if min_age && max_age && min_age > max_age
      errors[:base] << "Age minimum is greater than maximum"
    end
  end

  def next_year_or_season
    if year_or_season.match(/\A\d{4}-\d{2}\z/)
      Season.new(year_or_season).next.to_s
    else
      (year_or_season.to_i + 1).to_s
    end
  end
end
