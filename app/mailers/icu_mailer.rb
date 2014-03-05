class IcuMailer < ActionMailer::Base
  add_template_helper(CartsHelper)

  FROM = "no-reply@icu.ie"
  CONFIRMATION = "Confirmation of your Payment to the ICU"

  default from: FROM

  def test_email(to, subject, message)
    raise "'#{to}' is not a valid email address" unless Util::Mailgun.validate(to)
    @message = message
    @time = Time.now.to_s(:nosec)
    mail(to: to, subject: subject)
  end

  def payment_receipt(cart_id)
    @cart = Cart.find(cart_id)
    to = Rails.env == "development" ? "webmaster@icu.ie" : @cart.confirmation_email
    raise "invalid confirmation email (#{to})" unless Rails.env == "test" || Util::Mailgun.validate(to)
    mail(to: to, subject: CONFIRMATION)
  end
end
