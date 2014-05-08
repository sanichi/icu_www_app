class ImagesController < ApplicationController
  def index
    @images = Image.search(params, images_path)
    flash.now[:warning] = t("no_matches") if @images.count == 0
    save_last_search(:images)
  end

  def show
    @image = Image.find(params[:id])
    @prev = Image.where("id < ?", params[:id]).order(id: :desc).limit(1).first
    @next = Image.where("id > ?", params[:id]).order(id:  :asc).limit(1).first
    @entries = @image.journal_entries if current_user.roles.present?
  end
end
