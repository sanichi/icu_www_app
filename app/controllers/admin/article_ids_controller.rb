class Admin::ArticleIdsController < ApplicationController
  def index
    params[:active] = "true"
    @articles = Article.search(params, admin_article_ids_path, current_user, remote: true, per_page: 10)
  end
end
