class Fee::Subscription < Fee
  before_validation :set_dates, :set_more_info

  validates :start_date, :end_date, :sale_start, :sale_end, :age_ref_date, presence: true
  validates :name, uniqueness: { scope: :years, message: "duplicate subscription name and season" }
  validate :valid_season

  def description(full=false)
    full ? "#{name} ICU Subscription #{years}" : "#{years} #{name}"
  end

  def copy
    fee = self.dup
    fee.name = nil
    fee.amount = nil
    fee.becomes(Fee)
  end

  def rolloverable?
    Fee::Subscription.where(name: name, years: season.next.to_s).count == 0
  end

  def rollover
    fee = self.dup
    fee.advance_1_year
    fee.becomes(Fee)
  end

  def applies_to?(user)
    return false if new_player_required?
    return false unless user.player
    return false if Item::Subscription.any_duplicates(user.player, end_date).exists?
    true
  end

  def new_player_allowed?
    true
  end

  def new_player_required?
    name.match(/\bnew\b/i)
  end

  private

  def set_dates
    season = self.season
    unless season.error
      self.start_date = season.start
      self.end_date = season.end
      self.sale_start = season.start.months_ago(1)
      self.sale_end = season.end
      self.age_ref_date = season.end.beginning_of_year
      self.years = season.to_s
    end
  end

  def set_more_info
    self.url = "http://www.icu.ie/help/membership"
  end
end
