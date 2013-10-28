class Admin::UsersController < ApplicationController
  before_action :set_user, only: [:edit, :update, :destroy, :login]
  authorize_resource

  def index
    @users = User.search(params, admin_users_path)
    flash.now[:warning] = t("no_matches") if @users.count == 0
    save_last_search(:admin, :users)
  end

  def new
    @player = Player.find(params[:player_id]) # always invoked from a player
    @user = User.new(player_id: @player.id)
  end

  def create
    @user = User.new(user_params(:new))
    @user.status = "OK"
    @user.verified_at = DateTime.now

    if @user.save
      @user.journal(:create, current_user, request.ip)
      redirect_to [:admin, @user], notice: "User was successfully created"
    else
      @player = Player.find(@user.player_id)
      render action: "new"
    end
  end

  def show
    @user = User.includes(:player).find(params[:id])
    @entries = @user.journal_entries if current_user.roles.present?
  end

  def update
    if @user.update(user_params)
      @user.journal(:update, current_user, request.ip)
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
      @user.journal(:destroy, current_user, request.ip)
      @user.destroy
      redirect_to admin_users_path, notice: "User #{email} was successfully deleted"
    end
  end

  def login
    if !current_user.admin?
      redirect_to admin_user_path(@user), alert: "Only administrators can switch user"
    elsif @user.id == current_user.id
      redirect_to admin_user_path(@user), alert: "Can't switch to the current user"
    elsif @user.admin?
      redirect_to admin_user_path(@user), alert: "Can't switch to another administrator"
    else
      session[:user_id] = @user.id
      redirect_to home_path, notice: "#{t('session.signed_in_as')} #{@user.email}"
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params(new_record=false)
    extra = new_record ? [:email, :player_id, :expires_on] : [:status, :verify]
    params.require(:user).permit(*extra, :password, roles: [])
  end
end
