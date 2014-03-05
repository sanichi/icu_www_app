require 'spec_helper'

feature "Pay", slow: true do
  given(:player)                { create(:player) }
  given(:user)                  { create(:user) }

  given(:select_member)         { I18n.t("shop.cart.item.select_member") }
  given(:first_name)            { I18n.t("player.first_name") }
  given(:last_name)             { I18n.t("player.last_name") }
  given(:add_to_cart)           { I18n.t("shop.cart.item.add") }
  given(:shop)                  { I18n.t("shop.shop") }
  given(:current)               { I18n.t("shop.cart.current") }
  given(:checkout)              { I18n.t("shop.cart.checkout") }
  given(:pay)                   { I18n.t("shop.payment.card.pay") }
  given(:completed)             { I18n.t("shop.payment.completed") }
  given(:total)                 { I18n.t("shop.cart.total") }
  given(:confirmation_email_to) { I18n.t("shop.payment.confirmation_email_to") }
  given(:payment_time)          { I18n.t("shop.payment.time") }
  given(:gateway)               { I18n.t("shop.payment.error.gateway") }
  given(:bad_number)            { I18n.t("shop.payment.error.number") }
  given(:bad_expiry)            { I18n.t("shop.payment.error.expiry") }
  given(:bad_cvc)               { I18n.t("shop.payment.error.cvc") }
  given(:bad_name)              { I18n.t("shop.payment.error.name") }
  given(:bad_email)             { I18n.t("shop.payment.error.email") }

  given(:number_id)             { "number" }
  given(:month_id)              { "exp-month" }
  given(:year_id)               { "exp-year" }
  given(:email_id)              { "confirmation_email" }
  given(:name_id)               { "payment_name" }
  given(:cvc_id)                { "cvc" }

  given(:stripe)                { "stripe" }
  given(:number)                { "4242 4242 4242 4242" }
  given(:mm)                    { "01" }
  given(:yyyy)                  { (Date.today.year + 2).to_s }
  given(:cvc)                   { "123" }
  given(:force_submit)          { "\n" }

  given(:title)                 { "h3" }
  given(:item)                  { "li" }
  given(:error)                 { "div.alert-danger" }
  given(:card_declined)         { "Your card was declined." }
  given(:expired_card)          { "Your card's expiration date is incorrect." }
  given(:incorrect_cvc)         { "Your card's security code is incorrect." }

  def fill_in_all_and_click_pay(opt = {})
    opt.reverse_merge!(number: number, mm: mm, yyyy: yyyy, cvc: cvc, name: player.name, email: player.email)
    fill_in number_id, with: opt[:number] if opt[:number]
    select opt[:mm], from: month_id       if opt[:mm]
    select opt[:yyyy], from: year_id      if opt[:yyyy]
    fill_in cvc_id, with: opt[:cvc]       if opt[:cvc]
    fill_in name_id, with: opt[:name]     if opt[:name]
    fill_in email_id, with: opt[:email]   if opt[:email]
    click_button pay
  end

  def fill_in_number_and_click_pay(number)
    fill_in number_id, with: number
    click_button pay
  end

  def gateway_error(text)
    "#{gateway}: \"#{text}\""
  end

  feature "subscription" do
    given!(:subscription_fee)  { create(:subscription_fee) }

    before(:each) do
      visit shop_path
      click_link subscription_fee.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart
      click_link checkout
    end

    after(:each) do
      ActionMailer::Base.deliveries.clear
    end

    scenario "successful", js: true do
      cart = Cart.last
      subscription = Subscription.last

      expect(cart).to be_unpaid
      expect(cart.payment_completed).to be_nil
      expect(cart.payment_ref).to be_nil
      expect(cart.payment_method).to be_nil
      expect(cart.user).to be_nil

      expect(subscription).to be_unpaid
      expect(subscription.payment_method).to be_nil
      expect(subscription.source).to eq "www2"

      fill_in_all_and_click_pay

      expect(page).to have_css(title, text: completed)
      expect(page).to have_css(item, text: /\A#{total}: €#{"%.2f" % subscription.cost}\z/)
      expect(page).to have_css(item, text: /\A#{payment_time}: 20\d\d-\d\d-\d\d \d\d:\d\d GMT\z/)
      expect(page).to have_css(item, text: /\A#{confirmation_email_to}: #{player.email}\z/)

      cart.reload
      expect(cart).to be_paid
      expect(cart.user).to be_nil
      expect(cart.payment_completed).to be_present
      expect(cart.payment_ref).to be_present
      expect(cart.payment_method).to eq stripe
      expect(cart.payment_errors.count).to eq 0

      subscription.reload
      expect(subscription).to be_paid
      expect(subscription.payment_method).to eq stripe

      expect(ActionMailer::Base.deliveries.size).to eq 1
      email = ActionMailer::Base.deliveries.last
      expect(email.from.size).to eq 1
      expect(email.from.first).to eq IcuMailer::FROM
      expect(email.to.size).to eq 1
      expect(email.to.first).to eq player.email
      expect(email.subject).to eq IcuMailer::CONFIRMATION
      expect(email.body.decoded).to include(player.name(id: true))
      expect(email.body.decoded).to include("%.2f" % subscription.cost)
    end

    scenario "stripe errors", js: true do
      fill_in_all_and_click_pay(number: "4000000000000002")
      expect(page).to have_css(error, text: gateway_error(card_declined))
      subscription = Subscription.last
      expect(subscription).to be_unpaid
      cart = Cart.include_errors.last
      expect(cart).to be_unpaid
      expect(cart.user).to be_nil
      expect(cart.payment_errors.count).to eq 1
      payment_error = cart.payment_errors.last
      expect(payment_error.message).to eq card_declined
      expect(payment_error.details).to be_present
      expect(payment_error.payment_name).to eq player.name
      expect(payment_error.confirmation_email).to eq player.email
      expect(ActionMailer::Base.deliveries).to be_empty

      fill_in_number_and_click_pay("4000000000000069")
      expect(page).to have_css(error, text: gateway_error(expired_card))
      subscription.reload
      expect(subscription).to be_unpaid
      cart.reload
      expect(cart).to be_unpaid
      expect(cart.user).to be_nil
      expect(cart.payment_errors.count).to eq 2
      payment_error = cart.payment_errors.last
      expect(payment_error.message).to eq expired_card
      expect(payment_error.details).to be_present
      expect(payment_error.payment_name).to eq player.name
      expect(payment_error.confirmation_email).to eq player.email
      expect(ActionMailer::Base.deliveries).to be_empty

      login(user)
      click_link shop
      click_link current
      click_link checkout

      fill_in_all_and_click_pay(number: "4000000000000127")
      expect(page).to have_css(error, text: gateway_error(incorrect_cvc))
      subscription.reload
      expect(subscription).to be_unpaid
      cart.reload
      expect(cart).to be_unpaid
      expect(cart.user).to eq user
      expect(cart.payment_errors.count).to eq 3
      payment_error = cart.payment_errors.last
      expect(payment_error.message).to eq incorrect_cvc
      expect(payment_error.details).to be_present
      expect(payment_error.payment_name).to eq player.name
      expect(payment_error.confirmation_email).to eq player.email
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    scenario "client side errors", js: true do
      expect(PaymentError.count).to eq 0

      # Card.
      click_button pay
      expect(page).to have_css(error, text: bad_number)
      fill_in number_id, with: "1234"
      click_button pay
      expect(page).to have_css(error, text: bad_number)

      # Expiry.
      fill_in number_id, with: number
      click_button pay
      expect(page).to have_css(error, text: bad_expiry)

      # CVC.
      select mm, from: month_id
      select yyyy, from: year_id
      click_button pay
      expect(page).to have_css(error, text: bad_cvc)
      fill_in cvc_id, with: "1"
      click_button pay
      expect(page).to have_css(error, text: bad_cvc)

      # Name.
      fill_in cvc_id, with: cvc
      click_button pay
      expect(page).to have_css(error, text: bad_name)

      # Email.
      fill_in name_id, with: player.name
      click_button pay
      expect(page).to have_css(error, text: bad_email)
      fill_in email_id, with: "rubbish"
      click_button pay
      expect(page).to have_css(error, text: bad_email)

      expect(PaymentError.count).to eq 0
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end
end
