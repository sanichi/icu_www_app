class TournamentsController < ApplicationController
  def index
    @tournaments = Tournament.search(params, tournaments_path)
    flash.now[:warning] = t("no_matches") if @tournaments.count == 0
    save_last_search(:tournaments)
  end

  def show
    @tournament = Tournament.find(params[:id])
    @prev = Tournament.where("id < ?", params[:id]).order(id: :desc).limit(1).first
    @next = Tournament.where("id > ?", params[:id]).order(id:  :asc).limit(1).first
    @entries = @tournament.journal_entries if current_user.roles.present?
  end
end
