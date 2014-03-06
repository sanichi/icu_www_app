class Fee < ActiveRecord::Base
  TYPES = %w[Fee::Subscripsion Fee::Entri]

  validates :type, inclusion: { in: TYPES }
  validate :valid_dates, :valid_discount, :valid_url

  def season
    Season.new(years)
  end

  def rolloverable?
    respond_to?(:rollover) && rollover(:dry_run)
  end

  private

  def valid_season
    season = self.season
    errors.add(:years, season.error) if season.error
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

  def valid_url
    return if url.blank?
    uri = URI.parse(url)
    raise "invalid URL" unless uri.try(:scheme).try(:match, /\Ahttps?\z/) && uri.host.present? && uri.port.present?
    req = Net::HTTP.new(uri.host, uri.port)
    req.read_timeout = 10
    res = req.start { |http| http.head(uri.path.blank? ? "/" : uri.path) }
    raise "got bad response for this URL" unless res.kind_of?(Net::HTTPSuccess)
  rescue => e
    errors.add(:url, e.message)
  end
end
