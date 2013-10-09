class Admin::ClubsController < ApplicationController
  authorize_resource
  before_action :set_club, only: [:show, :edit, :update]

  def index
    @clubs = Club.search(params, admin_clubs_path)
    flash.now[:warning] = t("no_matches") if @clubs.count == 0
    save_last_search(:admin, :clubs)
  end

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
      render action: 'edit'
    end
  end

  private

  def set_club
    @club = Club.find(params[:id])
  end

  def club_params
    params[:club]
  end
end
