module SessionsHelper
  private

  def current_user
    return @current_user if @current_user
    if session[:user_id]
      @current_user = User.includes(:player).where(id: session[:user_id]).first
      logger.error("no user found for session user ID #{session[:user_id]}") unless @current_user
    end
    @current_user ||= User::Guest.new
  end

  def current_kart(option=nil)
    # If there's no memoized cart, see if there's one in the session.
    if !@current_kart && session[:kart_id]
      @current_kart = Kart.include_items.where(id: session[:kart_id], status: "unpaid").first
      unless @current_kart
        logger.error("no cart found for session cart ID #{session[:kart_id]}")
        session.delete(:kart_id)
      end
    end

    # If an unpaid cart exists return it immediately.
    return @current_kart if @current_kart && @current_kart.unpaid?

    # Ensure there's no paid cart hanging around.
    clear_current_kart

    # Create a new cart but only if requested.
    if option == :create
      @current_kart = Kart.create
      session[:kart_id] = @current_kart.id
    end

    # Return whatever we have left at this point (new empty cart or nil).
    @current_kart
  end

  def clear_current_kart
    @current_kart = nil
    session.delete(:kart_id)
  end

  def complete_kart(kart_id)
    clear_current_kart
    session[:completed_karts] ||= []
    session[:completed_karts].unshift kart_id
  end

  def completed_karts
    kart_ids = session[:completed_karts] || []
    kart_ids.map { |id| Kart.include_items.where(id: id, status: "paid").first }
  end

  def last_completed_kart
    kart_ids = session[:completed_karts] || []
    return if kart_ids.empty?
    Kart.include_items.where(id: kart_ids[0], status: "paid").first
  end
end
