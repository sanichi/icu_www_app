class ChampionsController < ApplicationController
  def index
    @champions = Champion.search(params, champions_path)
    flash.now[:warning] = t("no_matches") if @champions.count == 0
    save_last_search(:champions)
  end

  def show
    @champion = Champion.find(params[:id])
    @prev = Champion.where("id < ?", params[:id]).order(id: :desc).limit(1).first
    @next = Champion.where("id > ?", params[:id]).order(id:  :asc).limit(1).first
    @entries = @champion.journal_entries if current_user.roles.present?
  end
end
