class Admin::LoginsController < ApplicationController
  authorize_resource

  def index
    @logins = Login.search(params, admin_logins_path)
    flash.now[:warning] = t("no_matches") if @logins.count == 0
  end
end
