class RedirectsController < ApplicationController
  def redirect
    switch_locale(params[:locale])
    redirect_to params[:path] || root_path
  end
end
