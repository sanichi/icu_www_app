class Item::Subscription < Item
  validates :start_date, :end_date, presence: true, unless: Proc.new { |i| i.description.match(/life/i) }
  validates :player, presence: true, unless: Proc.new { |s| s.player_data.present? }
  validate :no_duplicates, :valid_player_data

  def season
    Season.new("#{start_date.try(:year)} #{end_date.try(:year)}")
  end

  def duplicate_of?(item, add_error=false)
    if type == item.type && fee.years == item.fee.years && player_id.present? && player_id == item.player_id
      errors.add(:base, I18n.t("item.error.subscription.already_in_cart", member: player.name(id: true), season: fee.years)) if add_error
      true
    elsif player_data.present? && new_player == item.new_player
      errors.add(:base, I18n.t("item.error.subscription.new_player_duplicate.cart", name: new_player.name, dob: new_player.dob.to_s)) if add_error
      true
    else
      false
    end
  end

  private

  def no_duplicates
    if player
      if end_date.present? && Item::Subscription.active.where(player_id: player.id, end_date: end_date).where.not(id: id).count > 0
        errors.add(:base, I18n.t("item.error.subscription.already_exists", member: player.name(id: true), season: season.to_s))
      elsif Item::Subscription.active.where(player_id: player.id, start_date: nil, end_date: nil).where.not(id: id).count > 0
        errors.add(:base, I18n.t("item.error.subscription.lifetime_exists", member: player.name(id: true)))
      end
    end
  end

  def valid_player_data
    if player_data.present?
      new_player = NewPlayer.from_json(player_data)
      if new_player
        player = new_player.to_player
        unless player.valid?
          logger.error("player data (#{player_data}) can't create a valid player (#{player.errors.to_a.join(', ')})")
          errors.add(:base, I18n.t("errors.alerts.application"))
        end
      else
        logger.error("player data (#{player_data}) is not valid")
        errors.add(:base, I18n.t("errors.alerts.application"))
      end
    end
  end
end
