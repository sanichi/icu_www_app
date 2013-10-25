class Admin::BadLoginsController < ApplicationController
  authorize_resource

  def index
    @bad_logins = BadLogin.search(params, admin_bad_logins_path)
    flash.now[:warning] = t("no_matches") if @bad_logins.count == 0
  end
end
