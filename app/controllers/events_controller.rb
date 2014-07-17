class EventsController < ApplicationController
  def index
    @events = Event.search(params, events_path)
    flash.now[:warning] = t("no_matches") if @events.count == 0
    save_last_search(@events, :events)
  end

  def show
    @event = Event.find(params[:id])
    @prev_next = Util::PrevNext.new(session, Event, params[:id])
    @entries = @event.journal_entries if current_user.roles.present?
  end
end
