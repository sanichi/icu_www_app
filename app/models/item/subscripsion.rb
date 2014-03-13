class Item::Subscripsion < Item
  validates :start_date, :end_date, presence: true, unless: Proc.new { |i| i.description.match(/life/i) }
  validates :player, presence: true
  validate :no_duplicates

  def season
    Season.new("#{start_date.try(:year)} #{end_date.try(:year)}")
  end

  def duplicate_of?(item, add_error=false)
    if type == item.type && player_id == item.player_id && fee.years == item.fee.years
      errors.add(:base, I18n.t("fee.subscription.error.already_in_cart", member: player.name(id: true))) if add_error
      true
    else
      false
    end
  end

  private

  def no_duplicates
    if player
      if end_date.present? && Item::Subscripsion.active.where(player_id: player.id, end_date: end_date).where.not(id: id).count > 0
        errors.add(:base, I18n.t("item.error.subscription.already_exists", member: player.name(id: true), season: season.to_s))
      elsif Item::Subscripsion.active.where(player_id: player.id, start_date: nil, end_date: nil).where.not(id: id).count > 0
        errors.add(:base, I18n.t("item.error.subscription.lifetime_exists", member: player.name(id: true)))
      end
    end
  end
end
