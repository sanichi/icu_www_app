class UsersController < ApplicationController
  before_action :set_user, except: [:new, :create, :confirm, :verify]

  def account
  end

  def preferences
  end

  def update_preferences
    if @user.update(user_params)
      switch_locale(@user.locale)      if @user.previous_changes[:locale]
      switch_header(@user.hide_header) if @user.previous_changes[:hide_header]
    end
    redirect_to preferences_path
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(new_user_params)

    if @user.sign_up && @user.save
      flash.now[:notice] = I18n.t("user.created")
      @user.journal(:create, @user, request.remote_ip)
      IcuMailer.verify_new_user_email(@user.id).deliver
      render action: "confirm"
    else
      flash.now[:alert] = I18n.t("user.create_failed")
      render action: "new"
    end
  end

  def update
    error = @user.change_password(params[:old_password], params[:new_password_1], params[:new_password_2])
    if error
      flash.now[:alert] = error
      %i[old_password new_password_1 new_password_2].each { |name| params[name] = "" }
      render "edit"
    else
      @user.journal(:update, current_user, request.remote_ip)
      flash[:notice] = "Password updated"
      redirect_to switch_from_tls(:account)
    end
  end

  def verify
    @user = User.find(params[:id])
    if @user.verified_at.blank? && params[:vp].present? && @user.verification_param == params[:vp]
      @user.update(verified_at: Time.now)
      @user.journal(:update, @user, request.remote_ip)
      flash[:notice] = I18n.t("user.completed_registration")
    end
    redirect_to switch_to_tls(:sign_in)
  end

  private

  def set_user
    @user = User.find(params[:id])
    authorize! :manage_preferences, @user
  end

  def user_params
    params.required(:user).permit(:theme, :locale, :hide_header)
  end

  def new_user_params
    params.required(:user).permit(:player_id, :ticket, :email, :password)
  end
end
