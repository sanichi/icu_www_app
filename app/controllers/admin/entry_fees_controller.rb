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
    @fee = EntryFee.find(params[:id]).dup
    authorize! :clone, @fee
    @fee.event_name = nil
    @fee.amount = nil
    render "new"
  end

  def rollover
    @fee = EntryFee.find(params[:id])
    authorize! :rollover, @fee
    if fee = @fee.rollover
      fee.journal(:create, current_user, request.ip)
      redirect_to [:admin, fee], notice: "Entry fee successfully rolled over"
    else
      redirect_to [:admin, @fee], alert: "Entry fee has already been rolled over"
    end
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
      flash.now.alert = @fee.errors[:base].first if @fee.errors[:base].any?
      render action: "edit"
    end
  end

  private

  def fee_params
    params[:entry_fee].permit(:event_name, :amount, :discounted_amount, :discount_deadline, :event_start, :event_end, :event_website, :sale_start, :sale_end, :player_id)
  end
end
