module SessionsHelper
  private

  def current_user
    return @current_user if @current_user
    if session[:user_id]
      @current_user = User.include_player.where(id: session[:user_id]).first
      unless @current_user
        details = failure_details(message: "the session contained an invalid user ID", user_id: session[:user_id])
        Failure.log("InvalidSessionUserID", details)
        session.delete(:user_id)
      end
    end
    @current_user ||= User::Guest.new
  end

  def current_cart(option=nil)
    # If there's no memoized cart, see if there's one in the session.
    if !@current_cart && session[:cart_id]
      @current_cart = Cart.include_items_plus.where(id: session[:cart_id], status: "unpaid").first
      unless @current_cart
        details = failure_details(message: "the session contained an invalid cart ID", cart_id: session[:cart_id])
        Failure.log("InvalidSessionCartID", details)
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
    cart_ids.map { |id| Cart.include_items_plus.where(id: id, status: "paid").first }
  end

  def last_completed_cart
    cart_ids = session[:completed_carts] || []
    return if cart_ids.empty?
    Cart.include_items_plus.where(id: cart_ids[0], status: "paid").first
  end
end
