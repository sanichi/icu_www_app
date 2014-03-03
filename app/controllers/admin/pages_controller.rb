class Admin::PagesController < ApplicationController
  def system_info
    authorize! :system_info, Page
    @env = Page.environment
  end
end
