class Admin::LoginsController < ApplicationController
  authorize_resource

  def index
    @logins = Login.search(params, admin_logins_path)
    flash.now[:warning] = t("no_matches") if @logins.count == 0
    save_last_search(@logins, :logins)
  end

  def show
    @login = Login.find(params[:id])
    @prev_next = Util::PrevNext.new(session, Login, params[:id], admin: true)
  end
end
