class PagesController < ApplicationController
  def home
    @news = News.search({ active: "true" }, news_index_path, per_page: 20)
  end

  def not_found
    render file: "#{Rails.root}/public/404", formats: [:html], layout: false, status: 404
  end
end
