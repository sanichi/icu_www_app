class Admin::ClubsController < ApplicationController
  authorize_resource
  before_action :set_club, only: [:edit, :update]

  def new
    @club = Club.new
  end

  def create
    @club = Club.new(club_params)

    if @club.save
      redirect_to @club, notice: "Club was successfully created"
    else
      render action: 'new'
    end
  end

  def update
    if @club.update(club_params)
      redirect_to @club, notice: "Club was successfully updated"
    else
      flash.now.alert = @club.errors[:base].first if @club.errors[:base].any?
      render action: 'edit'
    end
  end

  private

  def set_club
    @club = Club.find(params[:id])
  end

  def club_params
    params[:club].permit(:name, :web, :meetings, :address, :district, :city, :county, :province, :latitude, :longitude, :contact, :email, :phone, :active)
  end
end
