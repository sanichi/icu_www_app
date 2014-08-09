class Admin::FailuresController < ApplicationController
  before_action :set_failure, only: [:show, :update, :destroy]
  authorize_resource

  def index
    params[:active] = "true" if params[:active].nil?
    @failures = Failure.search(params, admin_failures_path)
    flash.now[:warning] = t("no_matches") if @failures.count == 0
    save_last_search(@failures, :failures)
  end

  def show
    @prev_next = Util::PrevNext.new(session, Failure, params[:id], admin: true)
  end

  def new
    raise "Simulated Failure"
  end

  def update
    @failure.update_column(:active, false)
    redirect_to last_search(:failures) || admin_failures_path
  end

  def destroy
    @failure.destroy
    redirect_to last_search(:failures) || admin_failures_path
  end

  private

  def set_failure
    @failure = Failure.find(params[:id])
  end
end
