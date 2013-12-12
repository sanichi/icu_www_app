class Admin::SubscriptionFeesController < ApplicationController
  authorize_resource
  before_action :set_fee, only: [:show, :edit, :update, :destroy, :rollover]

  def index
    @fees = SubscriptionFee.ordered.to_a
  end

  def show
    @entries = @fee.journal_entries if current_user.roles.present?
  end

  def rollover
    if fee = @fee.rollover
      fee.journal(:create, current_user, request.ip)
      redirect_to [:admin, fee], notice: "Subscription successfully rolled over"
    else
      redirect_to [:admin, @fee], alert: "Subscription has already been rolled over"
    end
  end

  def new
    @fee = SubscriptionFee.new
  end

  def create
    @fee = SubscriptionFee.new(fee_params)

    if @fee.save
      @fee.journal(:create, current_user, request.ip)
      redirect_to [:admin, @fee], notice: "Subscription fee was successfully created"
    else
      render action: "new"
    end
  end

  def update
    if @fee.update(fee_params)
      @fee.journal(:update, current_user, request.ip)
      redirect_to [:admin, @fee], notice: "Subscription fee was successfully updated"
    else
      flash.now.alert = @fee.errors[:base].first if @fee.errors[:base].any?
      render action: "edit"
    end
  end

  def destroy
    @fee.journal(:destroy, current_user, request.ip)
    @fee.destroy
    redirect_to admin_subscription_fees_path
  end

  private

  def set_fee
    @fee = SubscriptionFee.find(params[:id])
  end

  def fee_params
    params[:subscription_fee].permit(:category, :amount, :season_desc)
  end
end
