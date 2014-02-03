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

  def current_cart(option=nil)
    # If there's no memoized cart, see if there's one in the session.
    if !@current_cart && session[:cart_id]
      @current_cart = Cart.include_cartables.find_by(id: session[:cart_id])
      unless @current_cart
        logger.error("no cart found for session cart ID #{session[:cart_id]}")
        session.delete(:cart_id)
      end
    end

    # If a cart exists, we might be able to return it immediately.
    if @current_cart
      if option == :paid
        # Sometimes (e.g. for confirmation) we want a paid cart.
        return @current_cart if @current_cart.paid?
      else
        # But normally we want an upaid cart.
        return @current_cart if @current_cart.unpaid?
      end
    end

    # Clear the current cart (if there was one). Create a new one if the option is set.
    if option == :create
      @current_cart = Cart.create
      session[:cart_id] = @current_cart.id
    else
      @current_cart = nil
      session.delete(:cart_id)
    end

    # Return whatever we have left at this point (new empty cart or nil).
    @current_cart
  end

  def clear_cart
    @current_cart = nil
    session.delete(:cart_id)
  end
end
