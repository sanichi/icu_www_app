require 'spec_helper'

feature "Pay", slow: true do
  given(:player)             { create(:player) }

  given(:select_member)      { I18n.t("shop.cart.item.select_member") }
  given(:first_name)         { I18n.t("player.first_name") }
  given(:last_name)          { I18n.t("player.last_name") }
  given(:add_to_cart)        { I18n.t("shop.cart.item.add") }
  given(:checkout)           { I18n.t("shop.cart.checkout") }
  given(:pay)                { I18n.t("shop.payment.card.pay") }
  given(:total)              { I18n.t("shop.cart.total") }
  given(:confirmation_email) { I18n.t("shop.payment.confirmation_email") }
  given(:time_since)         { I18n.t("shop.payment.time_since") }
  given(:payment_method)     { I18n.t("shop.payment.method.method") }
  given(:stripe_label)       { I18n.t("shop.payment.method.stripe") }

  given(:number)             { "number" }
  given(:month)              { "exp-month" }
  given(:year)               { "exp-year" }
  given(:email)              { "confirmation_email" }
  given(:name)               { "payment_name" }
  given(:cvc)                { "cvc" }
  given(:stripe)             { "stripe" }
  given(:force_submit)       { "\n" }

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
    end

    scenario "successful", js: true do
      cart = Cart.last
      subscription = Subscription.last

      expect(cart).to be_unpaid
      expect(cart.payment_completed).to be_nil
      expect(cart.payment_ref).to be_nil
      expect(cart.payment_method).to be_nil

      expect(subscription).to be_unpaid
      expect(subscription.payment_method).to be_nil
      expect(subscription.source).to eq "www2"

      click_link checkout

      fill_in number, with: "4242 4242 4242 4242"
      select "01", from: month
      select Date.today.year + 2, from: year
      fill_in cvc, with: "123"
      fill_in name, with: player.name
      fill_in email, with: player.email

      click_button pay

      expect(page).to have_css("li", text: /\A#{total}: €#{"%.2f" % subscription.cost}\z/)
      expect(page).to have_css("li", text: /\A#{time_since}: .+ \(20\d\d-\d\d-\d\d \d\d:\d\d:\d\d\)\z/)
      expect(page).to have_css("li", text: /\A#{confirmation_email}: #{player.email}\z/)
      expect(page).to have_css("li", text: /\A#{payment_method}: #{stripe_label}\z/)

      cart.reload
      expect(cart).to be_paid
      expect(cart.payment_completed).to be_present
      expect(cart.payment_ref).to be_present
      expect(cart.payment_method).to eq stripe

      subscription.reload
      expect(subscription).to be_paid
      expect(subscription.payment_method).to eq stripe
    end
  end
end
