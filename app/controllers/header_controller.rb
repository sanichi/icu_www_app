class HeaderController < ApplicationController
  def control
    toggle_header if request.xhr?
  end
end
