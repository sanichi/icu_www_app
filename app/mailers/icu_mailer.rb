class IcuMailer < ActionMailer::Base
  add_template_helper(CartsHelper)

  FROM = "NO-REPLY@icu.ie"
  CONFIRMATION = "Confirmation of your Payment to the ICU"
  VERIFICATION = "Please verify your ICU login account email address"
  MAIL_STATS = "ICU mail statistics at %s"
  WEBMASTER = "webmaster@icu.ie"

  default from: FROM

  def test_email(to, subject, message)
    raise "'#{to}' is not a valid email address" unless Util::Mailgun.validate(to)
    @message = message
    @time = Time.now.to_s(:nosec)
    mail(to: to, subject: subject)
  end

  def payment_receipt(cart_id)
    @cart = Cart.find(cart_id)
    mail(to: payment_receipt_to(@cart), subject: CONFIRMATION)
  end

  def verify_new_user_email(user_id)
    @user = User.include_player.find(user_id)
    mail(to: @user.email, subject: VERIFICATION)
  end

  def mail_stats(stats)
    @stats = stats
    mail(to: WEBMASTER, subject: MAIL_STATS % Time.now.to_s(:db))
  end

  private

  def payment_receipt_to(cart)
    to = cart.confirmation_email
    unless Rails.env.test? || to.blank?
      raise "invalid confirmation email (#{to})" unless Util::Mailgun.validate(to)
    end
    Rails.env.development? || to.blank? ? "webmaster@icu.ie" : to
  end
end
