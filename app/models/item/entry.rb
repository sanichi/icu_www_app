class Item::Entry < Item
  validates :start_date, :end_date, :player, presence: true
  validate :no_duplicates

  def duplicate_of?(item, add_error=false)
    if type == item.type && player_id == item.player_id && fee_id == item.fee_id
      errors.add(:base, I18n.t("fee.entry.error.already_in_cart", member: player.name(id: true))) if add_error
      true
    else
      false
    end
  end

  private

  def no_duplicates
    if [player, start_date, end_date, description].all?(&:present?)
      if Item::Entry.active.where(player_id: player.id, description: description, start_date: start_date, end_date: end_date).where.not(id: id).count > 0
        errors.add(:base, I18n.t("item.error.entry.already_entered", member: player.name(id: true)))
      end
    end
  end
end
