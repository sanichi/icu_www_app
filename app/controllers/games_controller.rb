class GamesController < ApplicationController
  def index
    @games = Game.search(params, games_path)
    flash.now[:warning] = t("no_matches") if @games.count == 0
    save_last_search(@games, :games)
  end

  def show
    @game = Game.find(params[:id])
    @prev_next = Util::PrevNext.new(session, Game, params[:id])
    @entries = @game.journal_entries if can?(:update, Game)
    respond_to do |format|
      format.html
      format.pgn { send_data @game.to_pgn }
    end
  end
end
