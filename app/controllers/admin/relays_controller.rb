class Admin::RelaysController < ApplicationController
  before_action :set_relay, only: [:edit, :update, :destroy]
  authorize_resource

  def index
    @relays = Relay.all
  end

  def refresh
    if Relay.refresh
      flash[:notice] = "Relays were successfully refreshed from provider"
    else
      flash[:alert] = "There was a problem refreshing relays from provider"
    end
    redirect_to admin_relays_path
  end

  def show
    @relay = Relay.include_officer.find(params[:id])
    relays = Relay.all
    index = relays.index { |r| r.id == @relay.id }
    if index
      @next = relays[index + 1]
      @prev = relays[index - 1] if index > 0
    end
  end

  def new
    @relay = Relay.new
  end

  def create
    @relay = Relay.new(relay_params)

    if @relay.save
      redirect_to [:admin, @relay], notice: "Relay was successfully created"
    else
      flash_first_error(@relay, base_only: true)
      render action: "new"
    end
  end

  def update
    if @relay.update(relay_params)
      redirect_to [:admin, @relay], notice: "Relay was successfully updated"
    else
      flash_first_error(@relay, base_only: true)
      render action: "edit"
    end
  end

  def destroy
    @relay.destroy
    redirect_to admin_relays_path, notice: "Relay was successfully deleted"
  end

  private

  def set_relay
    @relay = Relay.find(params[:id])
  end

  def relay_params
    params[:relay].permit(:from, :officer_id)
  end
end
