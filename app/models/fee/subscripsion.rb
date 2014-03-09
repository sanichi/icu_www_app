class Fee::Subscripsion < Fee
  has_many :items, class_name: "Item::Subscripsion", foreign_key: "fee_id", inverse_of: :fee

  before_validation :set_dates

  validates :start_date, :end_date, :sale_start, :sale_end, :age_ref_date, presence: true
  validates :name, uniqueness: { scope: :end_date, message: "no more than one per season" }
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
    Fee::Subscripsion.where(name: name, years: season.next.to_s).count == 0
  end

  def rollover
    fee = self.dup
    fee.advance_1_year
    fee.becomes(Fee)
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
      self.years = season.to_s
    end
  end
end
