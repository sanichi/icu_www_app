class Admin::EventsController < ApplicationController
  before_action :set_event, only: [:edit, :update, :destroy]
  authorize_resource

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)
    @event.user_id = current_user.id

    if @event.save
      @event.journal(:create, current_user, request.remote_ip)
      redirect_to @event, notice: "Event was successfully created"
    else
      flash_first_error(@event, base_only: true)
      render action: "new"
    end
  end

  def update
    if @event.update(event_params)
      @event.journal(:update, current_user, request.remote_ip)
      redirect_to @event, notice: "Event was successfully updated"
    else
      flash_first_error(@event, base_only: true)
      render action: "edit"
    end
  end

  def destroy
    @event.journal(:destroy, current_user, request.remote_ip)
    @event.destroy
    redirect_to admin_events_path, notice: "Event was successfully deleted"
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params[:event].permit(:flyer, :name, :category, :location, :start_date, :end_date, :contact, :phone, :email, :url, :lat, :long, :prize_fund, :active, :note)
  end
end
