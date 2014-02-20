class Admin::RefundsController < ApplicationController
  authorize_resource

  def index
    @refunds = Refund.search(params, admin_refunds_path)
    flash.now[:warning] = t("no_matches") if @refunds.count == 0
    save_last_search(:admin, :refunds)
  end
end
