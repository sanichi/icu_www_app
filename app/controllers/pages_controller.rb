class PagesController < ApplicationController
  def home
  end

  def not_found
    render file: "#{Rails.root}/public/404", formats: [:html], layout: false, status: 404
  end
end
