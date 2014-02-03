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
      @current_cart = Cart.include_cartables.find_by(id: session[:cart_id], status: "unpaid")
      unless @current_cart
        logger.error("no cart found for session cart ID #{session[:cart_id]}")
        session.delete(:cart_id)
      end
    end

    # If an unpaid cart exists return it immediately.
    return @current_cart if @current_cart && @current_cart.unpaid?
    
    # Ensure there's no paid cart hanging around.
    clear_current_cart

    # Create a new cart but only if requested.
    if option == :create
      @current_cart = Cart.create
      session[:cart_id] = @current_cart.id
    end

    # Return whatever we have left at this point (new empty cart or nil).
    @current_cart
  end

  def clear_current_cart
    @current_cart = nil
    session.delete(:cart_id)
  end
  
  def complete_cart(cart_id)
    clear_current_cart
    session[:completed_carts] ||= []
    session[:completed_carts].unshift cart_id
  end

  def completed_carts
    cart_ids = session[:completed_carts] || []
    cart_ids.map { |id| Cart.include_cartables.find_by(id: id, status: "paid") }
  end

  def last_completed_cart
    cart_ids = session[:completed_carts] || []
    return if cart_ids.empty?
    Cart.include_cartables.find_by(id: cart_ids[0], status: "paid")
  end
end
