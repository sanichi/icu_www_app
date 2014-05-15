class UploadsController < ApplicationController
  def index
    @uploads = Upload.search(params, uploads_path, current_user)
    flash.now[:warning] = t("no_matches") if @uploads.count == 0
    save_last_search(:uploads)
  end
end
