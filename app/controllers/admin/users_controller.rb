class Admin::UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  authorize_resource

  def index
    @users = User.search(params, admin_users_path)
    flash.now[:warning] = t("no_matches") if @users.count == 0
    save_last_search
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to [:admin, @user], notice: "User was successfully updated"
    else
      render action: "edit"
    end
  end

  def destroy
    email = @user.email
    if reason = @user.reason_to_not_delete
      redirect_to admin_user_path(@user), alert: "Can't delete #{email} because this user #{reason}"
    else
      @user.destroy
      redirect_to admin_users_path, notice: "User #{email} was successfully deleted"
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:password, :expiry, :status, :verify, roles: [])
  end
end
