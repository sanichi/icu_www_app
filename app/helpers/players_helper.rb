module PlayersHelper
  def player_gender_menu(selected, default="any")
    counties = Player::GENDERS.map { |g| [t("player.gender.#{g}"), g] }
    counties.unshift [t(default), ""]
    options_for_select(counties, selected)
  end

  def player_order_menu(selected)
    orders = %w[last_name first_name].map { |col| [t("player.#{col}"), col] }
    orders.unshift [t("player.id_order"), "id"]
    options_for_select(orders, selected)
  end

  def player_relation_menu(selected)
    options_for_select(%w[= < >], selected)
  end

  def player_status_menu(selected, opt={})
    statuses = Player::STATUSES.map { |g| [t("player.status.#{g}"), g] }
    statuses.push [t("player.deceased"), "deceased"] if opt[:deceased]
    statuses.push [t("any"), ""] if opt[:any]
    options_for_select(statuses, selected)
  end
end
