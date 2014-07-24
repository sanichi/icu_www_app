class Fee < ActiveRecord::Base
  include Journalable
  include Normalizable
  include Pageable

  ATTRS = column_names.reject{ |n| n.match(/\A(id|type|created_at|updated_at)\z/) }
  journalize ATTRS, "/admin/fees/%d"

  TYPES = %w[Subscription Entry Other].map{ |t| "Fee::#{t}" }

  has_many :items, dependent: :nullify
  has_many :user_inputs, dependent: :destroy

  before_validation :normalize_attributes

  validates :type, inclusion: { in: TYPES }
  validates :name, presence: true
  validates :amount, numericality: { greater_than: Cart::MIN_AMOUNT, less_than: Cart::MAX_AMOUNT }, unless: Proc.new { |f| f.amount.blank? }
  validates :amount, presence: true, unless: Proc.new { |f| f.user_amount? }
  validates :days, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :valid_days, :valid_dates, :valid_discount, :valid_age_limits, :valid_rating_limits, :valid_url

  scope :alphabetic, -> { order(name: :asc) }
  scope :old_to_new, -> { order(end_date: :desc) }
  scope :new_to_old, -> { order(start_date: :asc) }
  scope :on_sale, -> { where(active: true).where("sale_start IS NULL OR sale_start <= ?", Date.today).where("sale_end IS NULL OR sale_end >= ?", Date.today) }

  def self.search(params, path)
    today = Date.today.to_s
    matches = all
    matches = matches.where(type: params[:type]) if params[:type].present?
    matches = matches.where(active: params[:active] == "true" ? true : false) if params[:active].present?
    case params[:sale]
    when "current" then matches = matches.alphabetic.where("(sale_start IS NULL OR sale_start <= ?) AND (sale_end IS NULL OR sale_end >= ?)", today, today)
    when "past"    then matches = matches.old_to_new.where("sale_end < ?", today)
    when "future"  then matches = matches.new_to_old.where("sale_start > ?", today)
    when "all"     then matches = matches.alphabetic
    end
    paginate(matches, params, path, per_page: 10)
  end

  def self.for_sale
    Fee.on_sale.each_with_object(Hash.new{|h,k| h[k] = []}) do |fee, hash|
      hash[fee.type].push(fee)
    end
  end

  def season
    Season.new(years)
  end

  def subtype(version=nil)
    Fee.subtype(type.presence || self.class.to_s, version)
  end

  def self.subtype(type, version=nil)
    sub_type = type.to_s.split("::").last
    return "Item::#{sub_type}" if version == :item
    sub_type.downcase
  end

  def user_amount?
    user_inputs.any? { |ui| ui.subtype == "amount" }
  end

  def deletable?
    items.count == 0
  end

  def rolloverable?
    respond_to?(:rollover)
  end

  def cloneable?
    respond_to?(:copy)
  end

  def within_sale_dates?
    return false if sale_start.present? && sale_start > Date.today
    return false if sale_end.present?   && sale_end   < Date.today
    true
  end

  def advance_1_year
    %w[start_date end_date sale_start sale_end discount_deadline age_ref_date].each do |date|
      send("#{date}=", send(date).years_since(1)) if send(date).present?
    end
    self.year = year + 1 if year.present?
    self.years = Season.new(self.years).next.to_s if years.present?
  end

  # Default behaviours. Can be overridden in subclasses.
  def applies_to?(user);   false end  # Should the user have a select me button?
  def new_player_allowed?; false end  # Can paying this fee create a new player?

  private

  def normalize_attributes
    normalize_blanks(:name, :years, :url)
    if url.present? && url.match(/\A[-\w]+(\.[-\w]+)*(:\d+)?\z/)
      self.url = "http://#{url}"
    end
  end

  def valid_season
    season = self.season
    errors.add(:years, season.error) if season.error
  end

  def valid_days
    if days.present? && days > 0
      if start_date.present? || end_date.present?
        self.end_date = start_date.days_since(days) if end_date.blank?
        self.start_date = end_date.days_ago(days) if start_date.blank?
        self.days = nil
      end
    end
  end

  def valid_dates
    if start_date.present? && end_date.present?
      if start_date > end_date
        errors.add(:start_date, "can't start after it ends")
      elsif end_date.year > start_date.year + 1
        errors.add(:end_date, "must end in the same or next year it starts")
      end
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

  def valid_discount
    if discounted_amount.present? && discounted_amount > amount
      errors.add(:discounted_amount, "discounted amount should be less than or equal to normal cost")
    end
  end

  def valid_age_limits
    if min_age || max_age
      unless age_ref_date.present?
        %i[min_age max_age].each { |m| errors[m] << "Age reference date required" if self.send(m) }
      end
    end
    if min_age && max_age && min_age > max_age
      errors[:base] << "Age minimum is greater than maximum"
    end
  end

  def valid_rating_limits
    return unless min_rating && max_rating
    if min_rating > max_rating
      errors[:base] << "Rating minimum is greater than maximum"
    elsif min_rating + 100 > max_rating
      errors[:base] << "Rating limits are too close"
    end
  end

  def valid_url
    return if url.blank?
    uri = URI.parse(url)
    raise "invalid URL" unless uri.try(:scheme).try(:match, /\Ahttps?\z/) && uri.host.present? && uri.port.present?
    # The rest of this check disabled in July 2014 during the migration because HEAD requests were failing (getting a 404)
    # on (the new) www.icu.ie when in maintenance mode (add_more_info in models/fee/subscription.rb was adding the URL).
    # req = Net::HTTP.new(uri.host, uri.port)
    # req.read_timeout = 10
    # res = req.start { |http| http.head(uri.path.blank? ? "/" : uri.path) }
    # raise "got bad response for this URL" unless res.kind_of?(Net::HTTPSuccess)
  rescue => e
    errors.add(:url, e.message)
  end
end
