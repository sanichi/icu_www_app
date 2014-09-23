class GamesController < ApplicationController
  def index
    @games = Game.search(params, games_path)
    @download = download_games_path(params) if count_ok?(@games.count) && can?(:download, Game)
    @db_path, @db_text, @db_details = Game.db_link
    flash.now[:warning] = t("no_matches") if @games.count == 0
    save_last_search(@games, :games)
  end

  def download
    authorize! :download, Game
    games = Game.matches(params)
    if count_ok?(games.count)
      send_data games.reduce(""){ |m,g| m += g.to_pgn }, filename: "icu_search.pgn", type: :pgn
    else
      redirect_to games_path
    end
  end

  def show
    @game = Game.find(params[:id])
    respond_to do |format|
      format.html do
        @prev_next = Util::PrevNext.new(session, Game, params[:id])
        @entries = @game.journal_search if can?(:update, Game)
      end
      format.pgn do
        authorize! :download, Game
        send_data @game.to_pgn, filename: "icu_#{@game.id}.pgn", type: :pgn
      end
    end
  end

  private

  def count_ok?(count)
    count > 0 && count <= Game::MAX_DOWNLOAD_SIZE
  end
end
