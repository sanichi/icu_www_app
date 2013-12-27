module SessionsHelper
  private

  def current_user
    return @current_user if @current_user
    if session[:user_id]
      @current_user = User.includes(:player).find_by(id: session[:user_id])
      logger.error("no user found for session user ID #{session[:user_id]}") unless @current_user
    end
    @current_user ||= User::Guest.new
  end

  def current_cart(create=false)
    return @current_cart if @current_cart
    if session[:cart_id]
      @current_cart = Cart.include_cartables.find_by(id: session[:cart_id])
      logger.error("no cart found for session cart ID #{session[:cart_id]}") unless @current_cart
    end
    return @current_cart unless create
    @current_cart ||= Cart.create
    session[:cart_id] = @current_cart.id
    @current_cart
  end
end
