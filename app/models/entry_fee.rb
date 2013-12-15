class EntryFee < ActiveRecord::Base
  include Journalable
  journalize %w[event_name amount discounted_amount discount_deadline event_start event_end sale_start sale_end player_id], "/admin/entry_fees/%d"

  belongs_to :player, -> { includes :users }

  before_validation :normalize_attributes, :default_attributes

  validates :event_name, presence: true, uniqueness: { scope: :year_or_season, message: "no more than one per year/season" }
  validates :amount, numericality: { greater_than: 0.0 }
  validates :amount, numericality: { greater_than: 0.0 }, allow_nil: true
  validates :discounted_amount, presence: true, if: Proc.new { |f| f.discount_deadline.present? }
  validates :discount_deadline, presence: true, if: Proc.new { |f| f.discounted_amount.present? }
  validates :event_start, :event_end, :sale_start, :sale_end, presence: true
  validate :check_dates, :check_discount, :check_manager

  scope :ordered, -> { order(event_start: :desc, event_name: :asc) }

  def description
    "#{event_name} #{year_or_season}"
  end

  def rolloverable?
    return false if event_start.year + 1 > Date.today.year + 1
    EntryFee.where(event_name: event_name, year_or_season: next_year_or_season).count == 0
  end

  def rollover
    return unless rolloverable?
    params = { event_name: event_name, amount: amount, discounted_amount: discounted_amount }
    %w[event_start event_end sale_start sale_end discount_deadline].map(&:to_sym).each do |atr|
      val = self.send(atr)
      params[atr] = val.present? ? val.years_since(1) : nil
    end
    EntryFee.create(params)
  end

  private

  def normalize_attributes
    %w[discount_deadline discounted_amount player_id].each do |atr|
      self.send("#{atr}=", nil) if self.send(atr).blank?
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
        self.year_or_season = season.desc unless season.error
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

  def next_year_or_season
    if year_or_season.match(/\A\d{4}-\d{2}\z/)
      Season.new(year_or_season).next
    else
      (year_or_season.to_i + 1).to_s
    end
  end

  def check_manager
    return if player_id.nil?
    if player_id == 0
      errors.add(:player_id, "please supply a player ID (a positive integer)")
    elsif player.nil?
      errors.add(:player_id, "invalid player ID")
    elsif player.email.blank?
      errors.add(:player_id, "this player doesn't have an email address")
    elsif player.users.empty?
      errors.add(:player_id, "this player has no login to the website")
    elsif player.users.select{ |u| u.expires_on > Date.today }.empty?
      errors.add(:player_id, "this player is not a current member")
    end
  end
end
