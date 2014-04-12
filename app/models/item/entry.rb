class Item::Entry < Item
  validates :start_date, :end_date, :player, presence: true
  validate :no_duplicates

  scope :any_duplicates, ->(fee, player) { active.where(fee_id: fee.id).where(player_id: player.id) }

  def duplicate_of?(item)
    if type == item.type && fee_id == item.fee_id && player_id == item.player_id
      I18n.t("item.error.entry.already_in_cart", member: player.name(id: true))
    else
      false
    end
  end

  private

  def no_duplicates
    if new_record? && [player, fee].all?(&:present?)
      if self.class.any_duplicates(fee, player).count > 0
        errors.add(:base, I18n.t("item.error.entry.already_entered", member: player.name(id: true)))
      end
    end
  end
end
