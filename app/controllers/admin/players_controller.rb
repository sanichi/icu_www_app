class Admin::PlayersController < ApplicationController
  authorize_resource
  before_action :set_player, only: [:edit, :update]

  def show
    @player = Player.includes(:users).find(params[:id])
    authorize! :show, @player # surprisingly, this is needed to ensure a player can only view their own data
    @entries = @player.journal_entries if current_user.roles.present?
  end

  def new
    @player = Player.new(source: "officer", status: "active", joined: Date.today.to_s)
  end

  def create
    @player = Player.new(player_params)

    if @player.save
      @player.journal(:create, current_user, request.ip)
      redirect_to [:admin, @player], notice: "Player was successfully created"
    else
      logger.error @player.errors.inspect
      render action: "new"
    end
  end

  def update
    if @player.update(player_params)
      @player.journal(:update, current_user, request.ip)
      redirect_to [:admin, @player], notice: "Player was successfully updated"
    else
      flash.now.alert = @player.errors[:base].first if @player.errors[:base].any?
      render action: "edit"
    end
  end

  private

  def set_player
    @player = Player.find(params[:id])
  end

  def player_params
    params[:player].permit(:first_name, :last_name, :player_id, :gender, :dob, :joined, :club_id, :fed, :email, :address, :home_phone, :mobile_phone, :work_phone, :player_title, :arbiter_title, :trainer_title, :note, :source, :status)
  end
end
