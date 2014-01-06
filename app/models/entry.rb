class Entry < ActiveRecord::Base
  include Cartable

  belongs_to :player
  belongs_to :entry_fee

  validates :player_id, numericality: { only_integer: true, greater_than: 0 }
  validates :entry_fee_id, numericality: { only_integer: true, greater_than: 0 }
  validates :cost, numericality: { greater_than: 0.0 }
  validates :description, :event_start, :event_end, presence: true

  validate :check_dates

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
end
