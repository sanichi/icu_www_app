class Fee::Entri < Fee
  before_validation :default_attributes

  validates :start_date, :end_date, :sale_start, :sale_end, presence: true
  validate :sale_end_date

  def description
    "#{name} #{year || years}"
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
