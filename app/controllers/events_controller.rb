class EventsController < ApplicationController
  def index
    @events = Event.search(params, events_path)
    flash.now[:warning] = t("no_matches") if @events.count == 0
    save_last_search(:events)
  end

  def show
    @event = Event.find(params[:id])
    @prev = Event.where("id < ?", params[:id]).order(id: :desc).limit(1).first
    @next = Event.where("id > ?", params[:id]).order(id:  :asc).limit(1).first
    @entries = @event.journal_entries if current_user.roles.present?
  end
end
