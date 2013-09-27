class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update]

  def show
    authorize! :manage_own_login, @user
  end

  def edit
    authorize! :manage_own_login, @user
  end

  def update
    authorize! :manage_own_login, @user
    if @user.update(user_params)
      redirect_to @user, notice: "User was successfully updated"
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
