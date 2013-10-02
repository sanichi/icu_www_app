class ApplicationController < ActionController::Base
  include SessionsHelper
  protect_from_forgery with: :exception

  rescue_from CanCan::AccessDenied do |exception|
    logger.warn "Access denied for #{exception.action} #{exception.subject} by user #{current_user.id} from #{request.ip}"
    redirect_to sign_in_path, alert: t("errors.messages.unauthorized")
  end

  def save_last_search(*paths)
    paths.unshift :last_search
    session[paths.join("_").to_sym] = request.fullpath
  end
end
