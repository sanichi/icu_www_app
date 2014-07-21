class ArticlesController < ApplicationController
  def index
    params[:active] = "true" unless can?(:create, Article)
    @articles = Article.search(params, articles_path, current_user)
    flash.now[:warning] = t("no_matches") if @articles.count == 0
    save_last_search(@articles, :articles)
  end

  def show
    @article = Article.include_player.include_series.find(params[:id])
    raise CanCan::AccessDenied.new(nil, :read, Article) unless @article.accessible_to?(current_user)
    @prev_next = Util::PrevNext.new(session, Article, params[:id])
    @entries = @article.journal_entries if current_user.roles.present?
  end

  def source
    authorize! :create, Article
    @article = Article.find(params[:id])
  rescue => e
    @error = e.message
  end
end
