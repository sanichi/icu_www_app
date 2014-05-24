class Admin::TournamentsController < ApplicationController
  before_action :set_tournament, only: [:edit, :update, :destroy]
  authorize_resource

  def new
    @tournament = Tournament.new
  end

  def create
    @tournament = Tournament.new(tournament_params)

    if @tournament.save
      @tournament.journal(:create, current_user, request.ip)
      redirect_to @tournament, notice: "Tournament was successfully created"
    else
      render action: "new"
    end
  end

  def update
    if @tournament.update(tournament_params)
      @tournament.journal(:update, current_user, request.ip)
      redirect_to @tournament, notice: "Tournament was successfully updated"
    else
      flash.now.alert = @tournament.errors[:base].first if @tournament.errors[:base].any?
      render action: "edit"
    end
  end

  def destroy
    @tournament.journal(:destroy, current_user, request.ip)
    @tournament.destroy
    redirect_to tournaments_path, notice: "Tournament was successfully deleted"
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:id])
  end

  def tournament_params
    params[:tournament].permit(:active, :category, :city, :details, :format, :name, :year)
  end
end
