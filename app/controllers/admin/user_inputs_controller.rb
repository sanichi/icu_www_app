class Admin::UserInputsController < ApplicationController
  before_action :set_user_input, only: [:show, :edit, :update, :destroy]
  authorize_resource

  def show
    @entries = @user_input.journal_search if can?(:create, UserInput)
  end

  def new
    @fee = Fee.where(id: params[:fee_id]).first
    if @fee
      @user_input = UserInput.new(fee: @fee)
      superclasses
    else
      flash[:alert] = "No or invalid fee ID supplied"
      redirect_to admin_fees_path
    end
  end

  def create
    @user_input = UserInput.new(user_input_params(:new_record))

    if @user_input.save
      @user_input.journal(:create, current_user, request.remote_ip)
      @user_input.fee.update_column(:amount, nil) if @user_input.subtype == "amount"
      redirect_to admin_user_input_path(@user_input), notice: "User input was successfully created"
    else
      flash_first_error(@user_input)
      @fee = Fee.where(id: params[:user_input][:fee_id]).first
      superclasses
      render "new"
    end
  end

  def edit
    superclasses
  end

  def update
    if @user_input.update(user_input_params)
      @user_input.journal(:update, current_user, request.remote_ip)
      redirect_to admin_user_input_path(@user_input), notice: "User input was successfully updated"
    else
      flash_first_error(@user_input)
      superclasses
      render "edit"
    end
  end

  def destroy
    fee = @user_input.fee
    @user_input.journal(:destroy, current_user, request.remote_ip)
    @user_input.destroy
    redirect_to admin_fee_path(fee), notice: "User input was successfully deleted"
  end

  private

  def set_user_input
    @user_input = UserInput.find(params[:id])
    @fee = @user_input.fee
  end

  def user_input_params(new_record=false)
    attrs = %i[label type]
    attrs.push(:fee_id) if new_record
    if UserInput::TYPES.include?(params[:user_input][:type])
      attrs += params[:user_input][:type].constantize.extras
    end
    params.required(:user_input).permit(*attrs)
  end

  def superclasses
    @user_input = @user_input.becomes(UserInput) if @user_input
    @fee = @fee.becomes(Fee) if @fee
  end
end
