class PlayersController < ApplicationController
  def index
    params.delete(:status) if current_user.guest? # guests don't get to search by status
    @players = Player.search(params, players_path)
    flash.now[:warning] = t("no_matches") if @players.count == 0
    save_last_search(:players)
  end
end
