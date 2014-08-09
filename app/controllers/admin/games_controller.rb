class Admin::GamesController < ApplicationController
  before_action :set_game, only: [:edit, :update, :destroy]
  authorize_resource

  def update
    normalize_newlines(:game, :moves)
    if @game.update(game_params)
      @game.journal(:update, current_user, request.remote_ip)
      redirect_to @game, notice: "Game was successfully updated"
    else
      flash_first_error(@game, base_only: true)
      render action: "edit"
    end
  end

  def destroy
    @game.journal(:destroy, current_user, request.remote_ip)
    @game.destroy
    redirect_to games_path, notice: "Game was successfully deleted"
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def game_params
    params[:game].permit(:annotator, :black, :black_elo, :date, :eco, :event, :fen, :moves, :ply, :result, :round, :site, :white, :white_elo)
  end
end
