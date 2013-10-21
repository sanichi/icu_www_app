class PlayersController < ApplicationController
  def index
    params[:status] = "active" if current_user.guest? # guests don't get to search by status
    @players = Player.search(params, players_path)
    flash.now[:warning] = t("no_matches") if @players.count == 0
    save_last_search(:players)
  end

  def show
    @player = Player.find(params[:id])
    #@entries = @player.journal_entries if current_user.roles.present?
  end
end
