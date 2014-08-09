class Admin::TournamentsController < ApplicationController
  before_action :set_tournament, only: [:edit, :update, :destroy]
  authorize_resource

  def new
    @tournament = Tournament.new
  end

  def create
    @tournament = Tournament.new(tournament_params)

    if @tournament.save
      @tournament.journal(:create, current_user, request.remote_ip)
      redirect_to @tournament, notice: "Tournament was successfully created"
    else
      flash_first_error(@tournament, base_only: true)
      render action: "new"
    end
  end

  def update
    normalize_newlines(:tournament, :details)
    if @tournament.update(tournament_params)
      @tournament.journal(:update, current_user, request.remote_ip)
      redirect_to @tournament, notice: "Tournament was successfully updated"
    else
      flash_first_error(@tournament, base_only: true)
      render action: "edit"
    end
  end

  def destroy
    @tournament.journal(:destroy, current_user, request.remote_ip)
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
