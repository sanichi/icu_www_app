class Fee::Entry < Fee
  before_validation :default_attributes

  validates :start_date, :end_date, :sale_start, :sale_end, presence: true
  validates :name, uniqueness: { scope: :start_date, message: "duplicate tournament name and start date" }

  validate :sale_end_date

  def description(full=false)
    parts = []
    parts.push "Entry for" if full
    parts.push name
    parts.push year || years
    parts.join(" ")
  end

  def copy
    fee = self.dup
    fee.name = nil
    fee.amount = nil
    fee.becomes(Fee)
  end

  def rolloverable?
    dups = Fee::Entry.where(name: name)
    dups = dups.where(year: year + 1) if year
    dups = dups.where(years: season.next.to_s) if years
    dups.count == 0
  end

  def rollover
    fee = self.dup
    fee.advance_1_year
    fee.becomes(Fee)
  end

  def applies_to?(user)
    return false unless user.player
    return false if Item::Entry.any_duplicates(self, user.player).exists?
    true
  end

  private

  def default_attributes
    if start_date.present?
      self.sale_end = start_date.days_ago(1) if sale_end.blank?
      self.sale_start = start_date.months_ago(3) if sale_start.blank?
      if end_date.present?
        if start_date.year == end_date.year
          self.year = start_date.year
          self.years = nil
        else
          season = Season.new("#{start_date.year} #{end_date.year}")
          self.years = season.to_s unless season.error
          self.year = nil
        end
      end
    end
  end

  def sale_end_date
    if sale_end.present? && start_date.present? && sale_end > start_date
      errors.add(:sale_end, "should end on or before the start date")
    end
  end
end
