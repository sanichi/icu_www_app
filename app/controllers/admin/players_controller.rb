class Admin::PlayersController < ApplicationController
  authorize_resource
  before_action :set_player, only: [:edit, :update]

  def new
    @player = Player.new(source: "officer", status: "active", joined: Date.today.to_s)
  end

  def create
    @player = Player.new(player_params)

    if @player.save
      #@player.journal(:create, current_user.name, request.ip)
      redirect_to @player, notice: "Player was successfully created"
    else
      logger.error @player.errors.inspect
      render action: "new"
    end
  end

  def update
    if @player.update(player_params)
      #@player.journal(:update, current_user.name, request.ip)
      redirect_to @player, notice: "Player was successfully updated"
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
    params[:player].permit(:first_name, :last_name, :player_id, :gender, :dob, :joined, :source, :status)
  end
end
