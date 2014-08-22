class PlayersController < ApplicationController
  before_action :set_player, only: [:edit, :update]

  def index
    params.delete(:status) if current_user.guest? # guests don't get to search by status
    @players = Player.search(params, players_path)
    flash.now[:warning] = t("no_matches") if @players.count == 0
    save_last_search(@players, :players)
  end

  def edit
    authorize! :manage_profile, @player
  end

  def update
    authorize! :manage_profile, @player
    if @player.update(player_params)
      @player.journal(:update, current_user, request.remote_ip)
      redirect_to [:admin, @player], notice: "Player was successfully updated"
    else
      flash_first_error(@player, base_only: true)
      render action: "edit"
    end
  end

  private

  def set_player
    @player = Player.find(params[:id])
  end

  def player_params
    params[:player].permit(:club_id, :email, :home_phone, :mobile_phone, :work_phone, :address, privacy: [])
  end
end
