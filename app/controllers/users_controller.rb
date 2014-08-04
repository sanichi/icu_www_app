class UsersController < ApplicationController
  before_action :set_user, except: [:new, :create, :confirm, :verify]

  def account
  end

  def preferences
  end

  def update_preferences
    if @user.update(user_params)
      if @user.previous_changes[:locale]
        switch_locale(@user.locale)
      end
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
      @user.journal(:create, @user, request.ip)
      IcuMailer.verify_new_user_email(@user.id).deliver
      render action: "confirm"
    else
      flash.now[:alert] = I18n.t("user.create_failed")
      render action: "new"
    end
  end

  def verify
    @user = User.find(params[:id])
    if @user.verified_at.blank? && params[:vp].present? && @user.verification_param == params[:vp]
      @user.update(verified_at: Time.now)
      @user.journal(:update, @user, request.ip)
      flash[:notice] = I18n.t("user.completed_registration")
    end
    redirect_to switch_to_ssl(:sign_in)
  end

  private

  def set_user
    @user = User.find(params[:id])
    authorize! :manage_preferences, @user
  end

  def user_params
    params.required(:user).permit(:theme, :locale)
  end

  def new_user_params
    params.required(:user).permit(:player_id, :ticket, :email, :password)
  end
end
