class SeriesController < ApplicationController
  def index
    @series = Series.search(params, series_index_path, current_user)
    flash.now[:warning] = t("no_matches") if @series.count == 0
    save_last_search(:series)
  end

  def show
    @series = Series.include_articles.find(params[:id])
    @entries = @series.journal_entries if current_user.roles.present?
  end
end
