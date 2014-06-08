module PgnsHelper
  def pgn_user_menu(selected)
    players = Player.joins(users: :pgns).order(:last_name, :first_name).select("DISTINCT players.*").all.map{ |p| [p.name(reversed: true), p.id] }
    players.unshift [t("user.any_editor"), ""]
    options_for_select(players, selected)
  end
end
