class GamesController < ApplicationController
  def index
    @games = Game.search(params, games_path)
    flash.now[:warning] = t("no_matches") if @games.count == 0
    save_last_search(:games)
  end

  def show
    @game = Game.find(params[:id])
    @prev = Game.where("id < ?", params[:id]).order(id: :desc).limit(1).first
    @next = Game.where("id > ?", params[:id]).order(id:  :asc).limit(1).first
    @entries = @game.journal_entries if current_user.roles.present?
  end
end
