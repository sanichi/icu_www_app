class Admin::EntryFeesController < ApplicationController
  def index
    authorize! :index, EntryFee
    @fees = EntryFee.search(params, admin_entry_fees_path)
  end

  def show
    @fee = EntryFee.find(params[:id])
    authorize! :show, @fee
    @entries = @fee.journal_entries if current_user.roles.present?
  end

  def clone
    authorize! :new, EntryFee
    @fee = EntryFee.find(params[:id]).dup
    @fee.event_name = nil
    @fee.amount = nil
    render "new"
  end

  def rollover
    authorize! :new, EntryFee
    fee = EntryFee.find(params[:id])
    @fee = EntryFee.new(fee.rollover_params)
    render "new"
  end

  def new
    authorize! :new, EntryFee
    @fee = EntryFee.new
  end

  def create
    authorize! :create, EntryFee
    @fee = EntryFee.new(fee_params)

    if @fee.save
      @fee.journal(:create, current_user, request.ip)
      redirect_to [:admin, @fee], notice: "Entry fee was successfully created"
    else
      flash_first_base_error(@fee)
      render action: "new"
    end
  end

  def edit
    @fee = EntryFee.find(params[:id])
    authorize! :edit, @fee
  end

  def update
    @fee = EntryFee.find(params[:id])
    authorize! :update, @fee
    if @fee.update(fee_params)
      @fee.journal(:update, current_user, request.ip)
      redirect_to [:admin, @fee], notice: "Entry fee was successfully updated"
    else
      flash_first_base_error(@fee)
      render action: "edit"
    end
  end

  def destroy
    @fee = EntryFee.find(params[:id])
    authorize! :destroy, @fee
    @fee.journal(:destroy, current_user, request.ip)
    @fee.destroy
    redirect_to admin_entry_fees_path
  end

  private

  def fee_params
    attrs =
      %i[event_name amount event_website player_id] +
      %i[discounted_amount discount_deadline] +
      %i[event_start event_end sale_start sale_end] +
      %i[min_rating max_rating]
    params[:entry_fee].permit(attrs)
  end
end
