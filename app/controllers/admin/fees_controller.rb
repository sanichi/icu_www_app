class Admin::FeesController < ApplicationController
  authorize_resource
  before_action :set_fee, only: [:show, :edit, :update, :destroy, :clone, :rollover]

  def index
    @fees = Fee.search(params, admin_fees_path)
  end

  def show
    @entries = @fee.journal_entries if current_user.roles.present?
  end

  def new
    @fee = Fee.new
  end

  def clone
    if @fee.cloneable?
      @fee = @fee.copy
      render "new"
    else
      flash[:alert] = "This fee is cannot be cloned"
      redirect_to "show"
    end
  end

  def rollover
    if @fee.rolloverable?
      @fee = @fee.rollover
      render "new"
    else
      flash[:alert] = "This fee cannot be rolled over"
      redirect_to "show"
    end
  end

  def create
    @fee = Fee.new(fee_params, :new_record)

    if @fee.save
      @fee.journal(:create, current_user, request.ip)
      redirect_to admin_fee_path(@fee), notice: "Fee was successfully created"
    else
      flash_first_base_error(@fee)
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
      flash_first_base_error(@fee)
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
      @entries = @fee.journal_entries if current_user.roles.present?
      render "show"
    end
  end

  private

  def set_fee
    @fee = Fee.find(params[:id])
  end

  def fee_params(new_record=false)
    attrs =
      %i[name amount discounted_amount] +
      %i[start_date end_date sale_start sale_end discount_deadline] +
      %i[age_ref_date min_age max_age] +
      %i[min_rating max_rating] +
      %i[years url type]
    params[:fee].permit(attrs)
  end
end
