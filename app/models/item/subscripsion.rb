class Item::Subscripsion < Item
  belongs_to :fee, class_name: "Fee::Subscripsion", inverse_of: :items

  validates :start_date, :end_date, presence: true, unless: Proc.new { |i| i.description.match(/life/i) }
  validates :player, presence: true
  validate :no_duplicates

  def season
    Season.new("#{start_date.try(:year)} #{end_date.try(:year)}")
  end

  private

  def no_duplicates
    if player
      if end_date.present? && Item::Subscripsion.active.where(player_id: player.id, end_date: end_date).where.not(id: id).count > 0
        errors.add(:base, I18n.t("item.subscription.error.already_exists", member: player.name(id: true), season: season.to_s))
      elsif Item::Subscripsion.active.where(player_id: player.id, start_date: nil, end_date: nil).where.not(id: id).count > 0
        errors.add(:base, I18n.t("item.subscription.error.lifetime_exists", member: player.name(id: true)))
      end
    end
  end
end
