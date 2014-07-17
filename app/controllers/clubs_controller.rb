class ClubsController < ApplicationController
  def index
    @clubs = Club.search(params, clubs_path)
    flash.now[:warning] = t("no_matches") if @clubs.count == 0
    save_last_search(@clubs, :clubs)
  end

  def show
    @club = Club.find(params[:id])
    @prev_next = Util::PrevNext.new(session, Club, params[:id])
    @entries = @club.journal_entries if current_user.roles.present?
  end
end
