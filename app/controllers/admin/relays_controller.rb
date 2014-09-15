class Admin::RelaysController < ApplicationController
  before_action :set_relay, only: [:edit, :update]
  authorize_resource

  def index
    @order = params[:order] == "to" ? :to : :from
    @relays = Relay.unscoped.order(@order).include_officer.all
    @enable_all_button  = @relays.reject(&:enabled).any?
    @disable_all_button = @relays.select(&:enabled).any?
  end

  def refresh
    if stats = Relay.refresh
      flash[:notice] = "Relays refreshed (#{stats})"
    else
      flash[:alert] = "There was a problem refreshing #{t("relay.provider")} relays"
    end
    redirect_to admin_relays_path
  end

  def enable_all
    if Relay.toggle_all(true)
      flash[:notice] = "All #{t("relay.provider")} relays enabled"
    else
      flash[:alert] = "There was a problem enabling all #{t("relay.provider")} relays"
    end
    redirect_to admin_relays_path
  end

  def disable_all
    if Relay.toggle_all(false)
      flash[:notice] = "All #{t("relay.provider")} relays disabled"
    else
      flash[:alert] = "There was a problem disabling all #{t("relay.provider")} relays"
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

  def update
    if @relay.update(relay_params)
      feedback = { notice: "Relay was successfully updated" }
      if @relay.route_updateable?
        if @relay.update_route?
          feedback[:notice] = "Relay and route were both successfully updated"
        else
          feedback = { alert: "Relay was updated but route update failed" }
        end
      end
      redirect_to [:admin, @relay], feedback
    else
      flash_first_error(@relay, base_only: true)
      render action: "edit"
    end
  end

  private

  def set_relay
    @relay = Relay.find(params[:id])
  end

  def relay_params
    params[:relay].permit(:officer_id, :to, :enabled)
  end
end
