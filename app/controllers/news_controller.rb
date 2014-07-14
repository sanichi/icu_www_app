class NewsController < ApplicationController
  def index
    params[:active] = "true" unless can?(:create, News)
    @news = News.search(params, news_index_path)
    flash.now[:warning] = t("no_matches") if @news.count == 0
    save_last_search(:news)
  end

  def show
    @news = News.include_player.find(params[:id])
    @entries = @news.journal_entries if current_user.roles.present?
  end
end
