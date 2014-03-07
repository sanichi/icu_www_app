class Item::Entri < Item
  belongs_to :fee, class_name: "Fee::Entri", inverse_of: :items

  validates :start_date, :end_date, :player, presence: true
  validate :no_duplicates

  private

  def no_duplicates
    if [player, start_date, end_date, description].all?(&:present?)
      if Item::Entri.active.where(player_id: player.id, description: description, start_date: start_date, end_date: end_date).where.not(id: id).count > 0
        errors.add(:base, I18n.t("item.error.entry.already_entered", member: player.name(id: true)))
      end
    end
  end
end
