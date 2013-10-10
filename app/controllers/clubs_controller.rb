class ClubsController < ApplicationController
  def index
    @clubs = Club.search(params, clubs_path)
    flash.now[:warning] = t("no_matches") if @clubs.count == 0
    save_last_search(:clubs)
  end

  def show
    @club = Club.find(params[:id])
  end
end
