class Admin::ClubsController < ApplicationController
  before_action :set_club, only: [:edit, :update]
  authorize_resource

  def new
    @club = Club.new
  end

  def create
    @club = Club.new(club_params)

    if @club.save
      @club.journal(:create, current_user, request.ip)
      redirect_to @club, notice: "Club was successfully created"
    else
      render action: "new"
    end
  end

  def update
    if @club.update(club_params)
      @club.journal(:update, current_user, request.ip)
      redirect_to @club, notice: "Club was successfully updated"
    else
      flash.now.alert = @club.errors[:base].first if @club.errors[:base].any?
      render action: "edit"
    end
  end

  private

  def set_club
    @club = Club.find(params[:id])
  end

  def club_params
    params[:club].permit(:name, :web, :meet, :address, :district, :city, :county, :lat, :long, :contact, :email, :phone, :active)
  end
end
