require 'spec_helper'

describe "Pay", js: true do
  let(:player)                { create(:player) }
  let(:user)                  { create(:user) }

  let(:add_to_cart)           { I18n.t("item.add") }
  let(:bad_cvc)               { I18n.t("shop.payment.error.cvc") }
  let(:bad_email)             { I18n.t("shop.payment.error.email") }
  let(:bad_expiry)            { I18n.t("shop.payment.error.expiry") }
  let(:bad_name)              { I18n.t("shop.payment.error.name") }
  let(:bad_number)            { I18n.t("shop.payment.error.number") }
  let(:checkout)              { I18n.t("shop.cart.checkout") }
  let(:cheque)                { I18n.t("shop.payment.method.cheque") }
  let(:completed)             { I18n.t("shop.payment.completed") }
  let(:confirm)               { I18n.t("confirm") }
  let(:confirmation_email_to) { I18n.t("shop.payment.confirmation_sent.success") }
  let(:current)               { I18n.t("shop.cart.current") }
  let(:dob)                   { I18n.t("player.abbrev.dob") }
  let(:email)                 { I18n.t("email") }
  let(:fed)                   { I18n.t("player.federation") }
  let(:first_name)            { I18n.t("player.first_name") }
  let(:gateway)               { I18n.t("shop.payment.error.gateway") }
  let(:gender)                { I18n.t("player.gender.gender") }
  let(:last_name)             { I18n.t("player.last_name") }
  let(:new_member)            { I18n.t("item.member.new") }
  let(:pay)                   { I18n.t("shop.payment.card.pay") }
  let(:payment_received)      { I18n.t("shop.payment.received") }
  let(:payment_registered)    { I18n.t("shop.payment.registered") }
  let(:payment_time)          { I18n.t("shop.payment.time") }
  let(:save)                  { I18n.t("save") }
  let(:season_ticket)         { I18n.t("user.ticket") }
  let(:select_member)         { I18n.t("item.member.select") }
  let(:shop)                  { I18n.t("shop.shop") }
  let(:total)                 { I18n.t("shop.cart.total") }

  let(:cvc_id)                { "cvc" }
  let(:email_id)              { "confirmation_email" }
  let(:expiry_id)             { "expiry" }
  let(:name_id)               { "payment_name" }
  let(:number_id)             { "number" }

  let(:cvc)                   { "123" }
  let(:expiry)                { "01 / #{(Date.today.year + 2).to_s}" }
  let(:force_submit)          { "\n" }
  let(:number)                { "4242 4242 4242 4242" }
  let(:stripe)                { "stripe" }

  let(:card_declined)         { "Your card was declined." }
  let(:expired_card)          { "Your card has expired." }
  let(:incorrect_cvc)         { "Your card's security code is incorrect." }

  let(:error)                 { "div.alert-danger" }
  let(:item)                  { "li" }
  let(:success)               { "div.alert-success" }
  let(:title)                 { "h3" }

  let!(:subscription_fee)     { create(:subscription_fee) }

  def add_something_to_cart
    visit shop_path
    click_link subscription_fee.description
    click_button select_member
    fill_in last_name, with: player.last_name + force_submit
    fill_in first_name, with: player.first_name + force_submit
    click_link player.id
    click_button add_to_cart
  end

  def fill_in_all_and_click_pay(opt = {})
    opt.reverse_merge!(number: number, expiry: expiry, cvc: cvc, name: player.name, email: player.email)
    fill_in number_id, with: opt[:number] if opt[:number]
    fill_in expiry_id, with: opt[:expiry] if opt[:expiry]
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

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  context "with card" do
    before(:each) do
      add_something_to_cart
      click_link checkout
    end

    it "successful" do
      cart = Cart.last
      expect(cart).to be_unpaid
      expect(cart.payment_completed).to be_nil
      expect(cart.payment_ref).to be_nil
      expect(cart.payment_method).to be_nil
      expect(cart.user).to be_nil
      expect(cart.items.count).to eq 1

      subscription = cart.items.first
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
      expect(cart.confirmation_sent).to be_true
      expect(cart.confirmation_error).to be_nil
      expect(cart.confirmation_text).to be_present

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

      text = email.body.decoded
      expect(text).to include(player.name(id: true))
      expect(text).to include("%.2f" % subscription.cost)
      expect(text).to include("#{season_ticket}: #{SeasonTicket.new(player.id, subscription.end_date.at_end_of_year).ticket}")
      expect(text).to eq cart.confirmation_text
    end

    it "stripe errors" do
      fill_in_all_and_click_pay(number: "4000000000000002")
      expect(page).to have_css(error, text: gateway_error(card_declined))
      subscription = Item::Subscription.last
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

      fill_in_number_and_click_pay(number: "4000000000000069")
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

    it "client side errors" do
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
      fill_in expiry_id, with: "99"
      click_button pay
      expect(page).to have_css(error, text: bad_expiry)

      # CVC.
      fill_in expiry_id, with: expiry
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

  context "with cash" do
    let(:payer_first_name) { "Payer's first name" }
    let(:payer_email)      { "Payer's email" }
    let(:payer_last_name)  { "Payer's last name" }
    let(:payer_method)     { "Payment method" }

    before(:each) do
      add_something_to_cart
    end

    it "successful" do
      expect(page).to have_link(checkout)
      expect(page).to_not have_link(payment_received)

      officer = login("membership")
      visit cart_path
      expect(page).to have_link(checkout)
      click_link payment_received

      fill_in payer_first_name, with: player.first_name
      fill_in payer_last_name, with: player.last_name
      select cheque, from: payer_method
      fill_in payer_email, with: player.email
      click_button confirm

      expect(page).to have_css(success, text: payment_registered)

      cart = Cart.last
      expect(cart).to be_paid
      expect(cart.payment_completed).to be_present
      expect(cart.payment_ref).to be_nil
      expect(cart.payment_method).to eq "cheque"
      expect(cart.user).to eq officer
      expect(cart.payment_errors.count).to eq 0
      expect(cart.items.count).to eq 1
      expect(cart.confirmation_sent).to be_true
      expect(cart.confirmation_error).to be_nil
      expect(cart.confirmation_text).to be_present

      subscription = cart.items.first
      expect(subscription).to be_paid
      expect(subscription.payment_method).to eq "cheque"
      expect(subscription.source).to eq "www2"

      expect(ActionMailer::Base.deliveries.size).to eq 1
      email = ActionMailer::Base.deliveries.last
      expect(email.from.size).to eq 1
      expect(email.from.first).to eq IcuMailer::FROM
      expect(email.to.size).to eq 1
      expect(email.to.first).to eq player.email
      expect(email.subject).to eq IcuMailer::CONFIRMATION

      text = email.body.decoded
      expect(text).to include(player.name(id: true))
      expect(text).to include("%.2f" % subscription.cost)
      expect(text).to include("#{season_ticket}: #{SeasonTicket.new(player.id, subscription.end_date.at_end_of_year).ticket}")
      expect(text).to eq cart.confirmation_text
    end

    it "without email" do
      login("membership")
      visit cart_path
      click_link payment_received

      fill_in payer_first_name, with: player.first_name
      fill_in payer_last_name, with: player.last_name
      select cheque, from: payer_method
      click_button confirm

      expect(page).to have_css(success, text: payment_registered)

      cart = Cart.last
      expect(cart).to be_paid
      expect(cart.confirmation_sent).to be_false
      expect(cart.confirmation_error).to eq "no email address available"
      expect(cart.confirmation_text).to be_present

      expect(ActionMailer::Base.deliveries.size).to eq 0

      text = cart.confirmation_text
      expect(text).to include(player.name(id: true))
      expect(text).to include("%.2f" % cart.total)
    end
  end

  context "new member" do
    let(:newbie)     { create(:new_player) }
    let(:newbie_fed) { ICU::Federation.find(newbie.fed).name }
    let(:newbie_sex) { I18n.t("player.gender.#{newbie.gender}") }

    before(:each) do
      visit shop_path
      click_link subscription_fee.description
      click_button new_member
      fill_in last_name, with: newbie.last_name
      fill_in first_name, with: newbie.first_name
      fill_in dob, with: newbie.dob.to_s
      select newbie_sex, from: gender
      select newbie_fed, from: fed
      fill_in email, with: newbie.email
      click_button save
      expect(page).to_not have_css(error)
      click_button add_to_cart
      click_link checkout
    end

    it "successful" do
      subscription = Item::Subscription.last
      expect(subscription.player_id).to be_nil
      expect(subscription.player_data).to be_present

      fill_in_all_and_click_pay

      expect(page).to have_css(title, text: completed)
      subscription.reload
      expect(subscription).to be_paid

      new_player = subscription.player
      expect(new_player).to be_present
      expect(new_player.first_name).to eq newbie.first_name
      expect(new_player.last_name).to eq newbie.last_name
      expect(new_player.dob).to eq newbie.dob
      expect(new_player.fed).to eq newbie.fed
      expect(new_player.gender).to eq newbie.gender
      expect(new_player.email).to eq newbie.email
      expect(new_player.status).to eq "active"
      expect(new_player.source).to eq "subscription"

      expect(ActionMailer::Base.deliveries.size).to eq 1
      email = ActionMailer::Base.deliveries.last

      text = email.body.decoded
      expect(text).to include(new_player.name(id: true))
      expect(text).to include("%.2f" % subscription.cost)
      expect(text).to include("#{season_ticket}: #{SeasonTicket.new(new_player.id, subscription.end_date.at_end_of_year).ticket}")
    end
  end
end
