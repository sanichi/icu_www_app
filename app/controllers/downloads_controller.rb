class DownloadsController < ApplicationController
  def index
    @downloads = Download.search(params, downloads_path, current_user)
    flash.now[:warning] = t("no_matches") if @downloads.count == 0
    save_last_search(@downloads, :downloads)
  end

  def show
    @download = Download.find(params[:id])
    raise CanCan::AccessDenied.new(nil, :read, Download) unless @download.accessible_to?(current_user)
    redirect_to @download.url
  end
end
