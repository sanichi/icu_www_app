class Admin::PagesController < ApplicationController
  before_action :authorize

  def session_info
    @session = Page.session(session)
  end

  def system_info
    @env = Page.environment
  end

  def test_email
    if request.xhr?
      to = params[:to].presence || "webmaster@icu.ie"
      subject = params[:subject].presence || "Test"
      message = params[:message].presence || "this is a test"
      begin
        IcuMailer.test_email(to, subject, message).deliver
        @message = "Email sent to #{to}"
        @error = false
      rescue => e
        @message = e.message
        @error = true
      end
      render "test_email.js"
    end
  end

  private

  def authorize
    authorize! :read, Page
  end
end
