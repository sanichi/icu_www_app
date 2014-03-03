class TestMailer < ActionMailer::Base
  default from: "no-reply@icu.ie"
  
  def test_email(to, subject, message)
    @message = message
    @time = Time.now.to_s(:nosec)
    mail(to: to, subject: subject)
  end
end
