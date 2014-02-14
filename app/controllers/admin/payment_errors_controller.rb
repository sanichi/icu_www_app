class Admin::PaymentErrorsController < ApplicationController
  authorize_resource

  def index
    @errors = PaymentError.search(params, admin_payment_errors_path)
    flash.now[:warning] = t("no_matches") if @errors.count == 0
    save_last_search(:admin, :payment_errors)
  end
end
