class Entry < ActiveRecord::Base
  include Cartable
  include Payable

  belongs_to :player
  belongs_to :entry_fee

  validates :player_id, numericality: { only_integer: true, greater_than: 0 }
  validates :entry_fee_id, numericality: { only_integer: true, greater_than: 0 }
  validates :cost, numericality: { greater_than: 0.0 }
  validates :description, :event_start, :event_end, presence: true

  validate :check_dates, :check_rating, :check_age

  def duplicate_of?(entry, add_error=false)
    if entry.player_id == player_id && entry.description == entry.description
      errors.add(:base, I18n.t("fee.entry.error.already_in_cart", member: player.name(id: true))) if add_error
      true
    else
      false
    end
  end

  private

  def check_dates
    if event_start.present? && event_end.present?
      if event_start > event_end
        errors.add(:event_start, "can't start after it ends")
      elsif event_end.year > event_start.year + 1
        errors.add(:event_end, "must end in the same or next year it starts")
      end
    end
  end

  def check_rating
    return unless player && player.latest_rating && entry_fee && (entry_fee.min_rating || entry_fee.max_rating)
    error, limit =
      case
      when entry_fee.min_rating && player.latest_rating < entry_fee.min_rating then ["too_low",  entry_fee.min_rating]
      when entry_fee.max_rating && player.latest_rating > entry_fee.max_rating then ["too_high", entry_fee.max_rating]
      end
    if error
      errors.add(:base, I18n.t("fee.entry.error.rating_#{error}", member: player.name, limit: limit))
    end
  end

  def check_age
    return unless player && player.dob && entry_fee && entry_fee.age_ref_date && (entry_fee.min_age || entry_fee.max_age)
    error, limit =
      case
      when entry_fee.min_age && player.age < entry_fee.min_age then ["too_young",  entry_fee.min_age]
      when entry_fee.max_age && player.age > entry_fee.max_age then ["too_old", entry_fee.max_age]
      end
    if error
      errors.add(:base, I18n.t("fee.entry.error.#{error}", member: player.name, limit: limit, date: entry_fee.age_ref_date))
    end
  end
end
