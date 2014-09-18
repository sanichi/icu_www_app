class Admin::MailEventsController < ApplicationController
  authorize_resource

  def index
    @events = MailEvent.search(params, admin_mail_events_path)
    @month = MailEvent.month
    flash.now[:warning] = t("no_matches") if @events.count == 0
  end
end
