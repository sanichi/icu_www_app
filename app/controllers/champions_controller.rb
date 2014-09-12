class ChampionsController < ApplicationController
  def index
    @champions = Champion.search(params, champions_path)
    flash.now[:warning] = t("no_matches") if @champions.count == 0
    save_last_search(@champions, :champions)
  end

  def show
    @champion = Champion.find(params[:id])
    @prev_next = Util::PrevNext.new(session, Champion, params[:id])
    @entries = @champion.journal_search if can?(:create, Champion)
  end
end
