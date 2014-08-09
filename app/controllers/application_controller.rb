class ApplicationController < ActionController::Base
  include SessionsHelper
  before_filter :set_locale
  protect_from_forgery with: :exception
  helper_method :switch_to_tls, :switch_from_tls, :last_search

  rescue_from CanCan::AccessDenied do |exception|
    logger.warn "Access denied for #{exception.action} #{exception.subject} by user #{current_user.id} from #{request.ip}"
    redirect_to switch_to_tls(:sign_in), alert: exception.message
  end

  # Sets up values in the session for lib/util/prev_next.rb and last_search in helpers/applicaion_helper.rb.
  def save_last_search(results, key)
    session["last_search_path_#{key}".to_sym] = request.fullpath
    session["last_search_list_#{key}".to_sym] = results.id_list
    session["last_search_time_#{key}".to_sym] = Time.now.to_i
    limit_saved_searches(key)
  end

  # Searches are saved in the session, which is stored in cookies, which have a size limit. So only store a few last searches.
  def limit_saved_searches(key)
    # Get session keys related to save_last_search.
    keys = session.keys.select { |k| k.to_s.match(/\Alast_search_time_/) }
    # Build array of pairs like this: [key used in save_last_search, time at save_last_search was called].
    pairs = keys.map do |k|
      key = k.to_s.sub(/\Alast_search_time_/, "")
      time = session[k].to_i
      [key, time]
    end
    # Don't delete the search we just saved.
    pairs.reject! { |k| k[0] == key.to_s }
    # If we have too many, then delete an appropriate number of the oldest.
    excess = pairs.size - 2
    if excess > 0
      pairs.sort{ |a, b| a[1] <=> b[1] }.take(excess).map{ |pair| pair[0] }.each do |key|
        delete_saved_search(key)
      end
    end
  end

  # Delete a saved search from the session.
  def delete_saved_search(key)
    %w[path list time].each { |cmp| session.delete("last_search_#{cmp}_#{key}".to_sym) }
  end

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

  def flash_first_error(model, now: true, base_only: false)
    error = nil
    if model.errors[:base].any?
      error = model.errors[:base].first
    elsif !base_only && model.errors.messages.any?
      message = model.errors.messages.first
      error = "#{message.first.to_s.capitalize}: #{message.last.first}"
    end
    if error
      target = now ? flash.now : flash
      target.alert = error
    end
  end

  def normalize_newlines(model, atr)
    if params[model] && params[model][atr].is_a?(String)
      params[model][atr].gsub!(/\r\n/, "\n")
    end
  end

  def switch_to_tls(prefix)
    if Rails.env.production? && !request.ssl?
      send("#{prefix}_url", protocol: "https")
    else
      send("#{prefix}_path")
    end
  end

  def switch_from_tls(prefix)
    if Rails.env.production? && request.ssl?
      send("#{prefix}_url", protocol: "http")
    else
      send("#{prefix}_path")
    end
  end

  def last_search(key)
    session["last_search_path_#{key}".to_sym]
  end
end
