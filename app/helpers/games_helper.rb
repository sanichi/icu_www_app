module GamesHelper
  def game_result_menu(selected, default=nil)
    results = Game::RESULTS.map{ |r| [r, r] }
    results.unshift [t(default), ""] if default
    options_for_select(results, selected)
  end
end
