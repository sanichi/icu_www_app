module NewsHelper
  def news_user_menu(selected)
    players = Player.joins(users: :news).order(:last_name, :first_name).select("DISTINCT players.*").all.map{ |p| [p.name(reversed: true), p.id] }
    players.unshift [t("user.any_editor"), ""]
    options_for_select(players, selected)
  end
end
