class Item::Entry < Item
  validates :start_date, :end_date, :player, presence: true
  validate :no_duplicates

  scope :any_duplicates, ->(player, fee) { active.where(player_id: player.id).where(fee_id: fee.id) }

  def duplicate_of?(item)
    if type == item.type && player_id == item.player_id && fee_id == item.fee_id
      I18n.t("item.error.entry.already_in_cart", member: player.name(id: true))
    else
      false
    end
  end

  private

  def no_duplicates
    if new_record? && [player, fee].all?(&:present?)
      if self.class.any_duplicates(player, fee).count > 0
        errors.add(:base, I18n.t("item.error.entry.already_entered", member: player.name(id: true)))
      end
    end
  end
end
