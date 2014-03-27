class NewPlayersController < ApplicationController
  def create
    @new_player = NewPlayer.new(new_player_params)
  end

  private

  def new_player_params
    params[:new_player][:joined] = Date.today
    params[:new_player].permit(*NewPlayer::ATTRS)
  end
end
