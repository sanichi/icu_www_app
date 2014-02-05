class UsersController < ApplicationController
  before_action :set_user

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

  private

  def set_user
    @user = User.find(params[:id])
    authorize! :manage_preferences, @user
  end

  def user_params
    params.required(:user).permit(:theme, :locale)
  end
end
