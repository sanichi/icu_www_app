class Admin::UploadsController < ApplicationController
  before_action :set_upload, only: [:show, :edit, :update, :destroy]
  authorize_resource

  def show
    @prev = Upload.where("id < ?", params[:id]).order(id: :desc).limit(1).first
    @next = Upload.where("id > ?", params[:id]).order(id:  :asc).limit(1).first
    @entries = @upload.journal_entries
  end

  def new
    @upload = Upload.new
  end

  def create
    @upload = Upload.new(upload_params)
    @upload.user_id = current_user.id

    if @upload.save
      @upload.journal(:create, current_user, request.ip)
      redirect_to [:admin, @upload], notice: "Upload was successfully created"
    else
      flash.now.alert = @upload.errors[:base].first if @upload.errors[:base].any?
      render action: "new"
    end
  end

  def update
    if @upload.update(upload_params)
      @upload.journal(:update, current_user, request.ip)
      redirect_to [:admin, @upload], notice: "Upload was successfully updated"
    else
      flash.now.alert = @upload.errors[:base].first if @upload.errors[:base].any?
      render action: "edit"
    end
  end

  def destroy
    @upload.journal(:destroy, current_user, request.ip)
    @upload.destroy
    redirect_to uploads_path, notice: "Upload was successfully deleted"
  end

  private

  def set_upload
    @upload = Upload.find(params[:id])
  end

  def upload_params
    params[:upload].permit(:data, :description, :year, :access)
  end
end
