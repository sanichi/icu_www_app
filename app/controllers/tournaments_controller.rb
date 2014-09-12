class TournamentsController < ApplicationController
  def index
    params[:active] = "true" unless can?(:manage, Tournament)
    @tournaments = Tournament.search(params, tournaments_path)
    flash.now[:warning] = t("no_matches") if @tournaments.count == 0
    save_last_search(@tournaments, :tournaments)
  end

  def show
    @tournament = Tournament.find(params[:id])
    @prev_next = Util::PrevNext.new(session, Tournament, params[:id])
    @entries = @tournament.journal_search if can?(:create, Tournament)
  end
end
