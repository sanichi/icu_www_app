module SessionsHelper
  private

  def current_user
    return @current_user if @current_user
    if session[:user_id]
      @current_user = User.find_by(id: session[:user_id])
      logger.error("no user found for session user ID #{session[:user_id]}") unless @current_user
    end
    @current_user ||= User::Guest.new
  end
end
