class Admin::ChampionsController < ApplicationController
  before_action :set_champion, only: [:edit, :update, :destroy]
  authorize_resource

  def new
    @champion = Champion.new
  end

  def create
    @champion = Champion.new(champion_params)

    if @champion.save
      @champion.journal(:create, current_user, request.ip)
      redirect_to @champion, notice: "Champion was successfully created"
    else
      render action: "new"
    end
  end

  def update
    if @champion.update(champion_params)
      @champion.journal(:update, current_user, request.ip)
      redirect_to @champion, notice: "Champion was successfully updated"
    else
      flash.now.alert = @champion.errors[:base].first if @champion.errors[:base].any?
      render action: "edit"
    end
  end

  def destroy
    @champion.journal(:destroy, current_user, request.ip)
    @champion.destroy
    redirect_to champions_path, notice: "Champion was successfully deleted"
  end

  private

  def set_champion
    @champion = Champion.find(params[:id])
  end

  def champion_params
    params[:champion].permit(:category, :notes, :winners, :year)
  end
end
