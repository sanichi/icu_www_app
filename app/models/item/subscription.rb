class Item::Subscription < Item
  validates :start_date, :end_date, presence: true, unless: Proc.new { |i| i.description.match(/life/i) }
  validates :player, presence: true, unless: Proc.new { |s| s.player_data.present? }
  validate :no_duplicates, :valid_player_data

  scope :lifetime_duplicates, ->(player)           { active.where(player_id: player.id, end_date: nil) }
  scope :season_duplicates,   ->(player, end_date) { active.where(player_id: player.id, end_date: end_date) }
  scope :any_duplicates,      ->(player, end_date) { active.where(player_id: player.id).where("end_date = ? OR end_date IS NULL", end_date) }

  def season
    Season.new("#{start_date.try(:year)} #{end_date.try(:year)}")
  end

  def duplicate_of?(item)
    if type == item.type && fee.years == item.fee.years && player_id.present? && player_id == item.player_id
      I18n.t("item.error.subscription.already_in_cart", member: player.name(id: true), season: fee.years)
    elsif player_data.present? && new_player == item.new_player
      I18n.t("item.error.subscription.new_player_duplicate.cart", name: new_player.name, dob: new_player.dob.to_s)
    else
      false
    end
  end

  private

  def no_duplicates
    if player && new_record?
      if end_date.present? && self.class.season_duplicates(player, end_date).count > 0
        errors.add(:base, I18n.t("item.error.subscription.already_exists", member: player.name(id: true), season: season.to_s))
      elsif self.class.lifetime_duplicates(player).count > 0
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
