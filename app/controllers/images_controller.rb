class ImagesController < ApplicationController
  def index
    @images = Image.search(params, images_path)
    flash.now[:warning] = t("no_matches") if @images.count == 0
    save_last_search(@images, :images)
  end

  def show
    @image = Image.find(params[:id])
    @prev_next = Util::PrevNext.new(session, Image, params[:id])
    @entries = @image.journal_entries if can?(:create, Image)
  end
end
