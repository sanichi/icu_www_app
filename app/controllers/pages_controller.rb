class PagesController < ApplicationController
  def home
  end

  def system_info
    authorize! :system_info, Page
    @env = Page.environment
  end

  def not_found
    render file: "#{Rails.root}/public/404", formats: [:html], layout: false, status: 404
  end
end
