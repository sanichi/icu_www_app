module GamesHelper
  def game_result_menu(selected)
    results = Game::RESULTS.map{ |r| [r, r] }
    results.unshift [t("game.any_result"), ""]
    options_for_select(results, selected)
  end
end
