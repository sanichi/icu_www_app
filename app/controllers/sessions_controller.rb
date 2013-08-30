class SessionsController < ApplicationController
  def new
  end

  def create
    begin
      user = User.authenticate!(params[:email], params[:password])
      session[:user_id] = user.id
      flash.notice = "#{t('session.signed_in_as')} #{user.email}"
      redirect_to home_path
    rescue User::SessionError => e
      flash.now.alert = t("session.#{e.message}")
      render "new"
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to sign_in_path, notice: t("session.signed_out")
  end
end
