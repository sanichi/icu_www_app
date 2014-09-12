class Admin::PlayersController < ApplicationController
  before_action :set_player, only: [:edit, :update]
  authorize_resource

  def show
    @player = Player.includes(:users).find(params[:id])
    authorize! :show, @player # for some reason, this is needed to ensure a player can only view their own data
    @prev_next = Util::PrevNext.new(session, Player, params[:id], admin: true) if can?(:manage, Player)
    @entries = @player.journal_search if can?(:create, Player)
  end

  def new
    @player = Player.new(source: "officer", status: "active", joined: Date.today.to_s)
  end

  def create
    @player = Player.new(player_params)

    if @player.save
      @player.journal(:create, current_user, request.remote_ip)
      redirect_to [:admin, @player], notice: "Player was successfully created"
    else
      flash_first_error(@player, base_only: true)
      render action: "new"
    end
  end

  def update
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
    attrs =
      %i[first_name last_name gender dob joined fed club_id] +
      %i[email address home_phone mobile_phone work_phone] +
      %i[player_title arbiter_title trainer_title] +
      %i[player_id note source status]
    params[:player].permit(*attrs, privacy: [])
  end
end
