class Admin::FeesController < ApplicationController
  before_action :set_fee, only: [:show, :edit, :update, :destroy, :clone, :rollover]
  authorize_resource

  def index
    @fees = Fee.search(params, admin_fees_path)
  end

  def show
    stuff_for_show
  end

  def new
    @fee = Fee.new
    @fee.type = params[:type] if Fee::TYPES.include?(params[:type])
  end

  def clone
    if @fee.cloneable?
      @fee = @fee.copy
      render "new"
    else
      flash[:alert] = "This fee is can't be cloned"
      redirect_to admin_fee_path(@fee)
    end
  end

  def rollover
    if @fee.rolloverable?
      @fee = @fee.rollover
      render "new"
    else
      flash[:alert] = "This fee can't be rolled over because it would create a duplicate"
      redirect_to admin_fee_path(@fee)
    end
  end

  def create
    @fee = Fee.new(fee_params(:new_record))

    if @fee.save
      @fee.journal(:create, current_user, request.ip)
      redirect_to admin_fee_path(@fee), notice: "Fee was successfully created"
    else
      flash_first_error(@fee, now: true)
      @fee = @fee.becomes(Fee)
      render "new"
    end
  end

  def edit
    @fee = @fee.becomes(Fee)
  end

  def update
    if @fee.update(fee_params)
      @fee.journal(:update, current_user, request.ip)
      redirect_to admin_fee_path(@fee), notice: "Fee was successfully updated"
    else
      flash_first_error(@fee, now: true)
      @fee = @fee.becomes(Fee)
      render "edit"
    end
  end

  def destroy
    if @fee.deletable?
      @fee.journal(:destroy, current_user, request.ip)
      @fee.destroy
      redirect_to admin_fees_path, notice: "Fee was successfully deleted"
    else
      flash.now[:alert] = "This fee can't be deleted as it is linked to one or more cart items"
      stuff_for_show
      render "show"
    end
  end

  private

  def set_fee
    @fee = Fee.find(params[:id])
  end

  def fee_params(new_record=false)
    attrs = case params[:fee][:type]
      when "Fee::Subscription" then %i[years]
      when "Fee::Entry"        then %i[start_date end_date sale_start sale_end discounted_amount discount_deadline min_rating max_rating age_ref_date url]
      when "Fee::Other"        then %i[start_date end_date sale_start sale_end discounted_amount discount_deadline min_rating max_rating age_ref_date url days player_required]
      else []
    end
    if attrs.any?
      attrs += %i[name amount min_age max_age active]
      attrs.push(:type) if new_record
    end
    params[:fee].permit(attrs)
  end

  def stuff_for_show
    @entries = @fee.journal_entries if current_user.roles.present?
    @inputs = @fee.user_inputs
  end
end
