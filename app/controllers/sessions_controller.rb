class SessionsController < ApplicationController
  def create
    begin
      user = User.authenticate!(params[:email], params[:password], request.ip)
      session[:user_id] = user.id
      session[:old_locale] = session[:locale] || I18n.default_locale
      switch_locale(user.locale)
      redirect_to switch_from_ssl(:home), notice: "#{t('session.signed_in_as')} #{user.email}"
    rescue User::SessionError => e
      flash.now.alert = t("session.#{e.message}")
      render "new"
    end
  end

  def destroy
    if session[:user_id]
      %i[user_id cart_id completed_carts].each { |key| session.delete(key) }
      switch_locale(session.delete(:old_locale))
      redirect_to switch_to_ssl(:sign_in), notice: t("session.signed_out")
    else
      redirect_to switch_to_ssl(:sign_in)
    end
  end
end
