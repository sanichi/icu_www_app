class Admin::DownloadsController < ApplicationController
  before_action :set_download, only: [:show, :edit, :update, :destroy]
  authorize_resource

  def show
    @prev_next = Util::PrevNext.new(session, Download, params[:id], admin: true)
    @entries = @download.journal_entries
  end

  def new
    @download = Download.new
  end

  def create
    @download = Download.new(download_params)
    @download.user_id = current_user.id

    if @download.save
      @download.journal(:create, current_user, request.ip)
      redirect_to [:admin, @download], notice: "Download was successfully created"
    else
      flash.now.alert = @download.errors[:base].first if @download.errors[:base].any?
      render action: "new"
    end
  end

  def update
    if @download.update(download_params)
      @download.journal(:update, current_user, request.ip)
      redirect_to [:admin, @download], notice: "Download was successfully updated"
    else
      flash.now.alert = @download.errors[:base].first if @download.errors[:base].any?
      render action: "edit"
    end
  end

  def destroy
    @download.journal(:destroy, current_user, request.ip)
    @download.destroy
    redirect_to downloads_path, notice: "Download was successfully deleted"
  end

  private

  def set_download
    @download = Download.find(params[:id])
  end

  def download_params
    params[:download].permit(:data, :description, :year, :access)
  end
end
