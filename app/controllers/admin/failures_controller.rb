class Admin::FailuresController < ApplicationController
  authorize_resource

  def index
    @failures = Failure.search(params, admin_failures_path)
    flash.now[:warning] = t("no_matches") if @failures.count == 0
    save_last_search(@failures, :failures)
  end

  def show
    @failure = Failure.find(params[:id])
    @prev_next = Util::PrevNext.new(session, Failure, params[:id], admin: true)
  end

  def new
    raise "Simulated Failure"
  end

  def destroy
    @failure = Failure.find(params[:id])
    @failure.destroy
    redirect_to admin_failures_path, notice: "Failure was successfully deleted"
  end
end
