class SessionsController < ApplicationController
  def create
    begin
      user = User.authenticate!(params[:email], params[:password], request.remote_ip)
      session[:user_id] = user.id
      session[:old_locale] = session[:locale] || I18n.default_locale
      session[:old_hide_header] = !show_header?
      switch_locale(user.locale)
      switch_header(user.hide_header)
      last_page_before_sign_in_or_home("#{t('session.signed_in_as')} #{user.email}")
    rescue User::SessionError => e
      flash.now.alert = t("session.#{e.message}")
      render "new"
    end
  end

  def destroy
    if session[:user_id]
      %i[user_id cart_id completed_carts].each { |key| session.delete(key) }
      switch_locale(session.delete(:old_locale))
      switch_header(session.delete(:old_hide_header))
      last_page_before_sign_in_or_home(t("session.signed_out"))
    else
      redirect_to switch_to_tls(:sign_in)
    end
  end

  private

  def last_page_before_sign_in_or_home(notice)
    goto = session[:last_page_before_sign_in]
    goto = :home unless goto.present? && goto.match(/\A\//)
    redirect_to switch_from_tls(goto), notice: notice
  end
end
