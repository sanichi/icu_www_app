class ArticlesController < ApplicationController
  def index
    params[:active] = "true" unless can?(:create, Article)
    @articles = Article.search(params, articles_path, current_user)
    flash.now[:warning] = t("no_matches") if @articles.count == 0
    save_last_search(:articles)
  end

  def show
    @article = Article.find(params[:id])
    raise CanCan::AccessDenied.new(nil, :read, Article) unless @article.accessible_to?(current_user)
    @entries = @article.journal_entries if current_user.roles.present?
  end
end
