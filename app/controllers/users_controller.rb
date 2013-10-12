class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update]

  def show
    authorize! :manage_preferences, @user
  end

  def edit
    authorize! :manage_preferences, @user
  end

  def update
    authorize! :manage_preferences, @user
    if @user.update(user_params)
      switch_locale(@user.locale) if @user.previous_changes[:locale]
      redirect_to @user, notice: t("user.updated")
    else
      render action: "edit"
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:theme, :locale)
  end
end
