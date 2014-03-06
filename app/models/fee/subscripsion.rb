class Fee::Subscripsion < Fee
  before_validation :set_dates

  validates :start_date, :end_date, :sale_start, :sale_end, :age_ref_date, presence: true
  validate :valid_season

  def description
    "#{years} #{name}"
  end

  def rollover(dry_run=false)
    return if season.next > Season.new.next
    return unless Fee::Subscripsion.where(name: name, years: season.next.to_s).count == 0
    return true if dry_run
    Fee::Subscripsion.create(name: name, years: season.next.to_s, amount: amount)
  end

  private

  def set_dates
    season = self.season
    unless season.error
      self.start_date = season.start
      self.end_date = season.end
      self.sale_start = season.start.months_ago(1)
      self.sale_end = season.end
      self.age_ref_date = season.start
    end
  end
end
