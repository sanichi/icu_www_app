class ApplicationController < ActionController::Base
  include SessionsHelper
  before_filter :set_locale
  protect_from_forgery with: :exception

  rescue_from CanCan::AccessDenied do |exception|
    logger.warn "Access denied for #{exception.action} #{exception.subject} by user #{current_user.id} from #{request.ip}"
    redirect_to sign_in_path, alert: exception.message
  end

  def save_last_search(*paths)
    paths.unshift :last_search
    session[paths.join("_").to_sym] = request.fullpath
  end

  private

  def set_locale
    if admin_path?
      I18n.locale = I18n.default_locale
    elsif !User.locale?(session[:locale])
      session[:locale] = I18n.locale = I18n.default_locale
    else
      I18n.locale = session[:locale]
    end
  end

  def switch_locale(locale)
    if User::LOCALES.include?(locale)
      session[:locale] = I18n.locale = locale
    end
  end

  def admin_path?
    controller_path.match(/^admin\//)
  end

  def flash_first_error(model, now: false)
    error = nil
    if model.errors[:base].any?
      error = model.errors[:base].first
    elsif model.errors.messages.any?
      message = model.errors.messages.first
      error = "#{message.first.to_s.capitalize}: #{message.last.first}"
    end
    if error
      target = now ? flash.now : flash
      target.alert = error
    end
  end
end
