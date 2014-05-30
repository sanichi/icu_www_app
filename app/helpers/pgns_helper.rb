module PgnsHelper
  def pgn_user_menu(selected)
    players = Player.joins(users: :pgns).select("DISTINCT players.*").all.map{ |p| [p.name, p.id] }
    players.unshift [t("user.any"), ""]
    options_for_select(players, selected)
  end
end
