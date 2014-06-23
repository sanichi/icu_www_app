class Admin::ArticlesController < ApplicationController
  before_action :set_article, only: [:edit, :update, :destroy]
  authorize_resource

  def new
    @article = Article.new
  end

  def create
    @article = Article.new(article_params)
    @article.user_id = current_user.id

    if @article.save
      @article.journal(:create, current_user, request.ip)
      redirect_to @article, notice: "Article was successfully created"
    else
      flash.now.alert = @article.errors[:base].first if @article.errors[:base].any?
      render action: "new"
    end
  end

  def update
    normalize_newlines(:article, :text)
    if @article.update(article_params)
      @article.journal(:update, current_user, request.ip)
      redirect_to @article, notice: "Article was successfully updated"
    else
      flash.now.alert = @article.errors[:base].first if @article.errors[:base].any?
      render action: "edit"
    end
  end

  def destroy
    @article.journal(:destroy, current_user, request.ip)
    @article.destroy
    redirect_to articles_path, notice: "Article was successfully deleted"
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def article_params
    params[:article].permit(:access, :active, :author, :category, :markdown, :text, :title, :year)
  end
end
