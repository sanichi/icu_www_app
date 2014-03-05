require 'spec_helper'

feature "Refunds", slow: true do
  given(:player)                { create(:player) }

  given(:select_member)         { I18n.t("shop.cart.item.select_member") }
  given(:first_name)            { I18n.t("player.first_name") }
  given(:last_name)             { I18n.t("player.last_name") }
  given(:add_to_cart)           { I18n.t("shop.cart.item.add") }
  given(:checkout)              { I18n.t("shop.cart.checkout") }
  given(:continue)              { I18n.t("shop.cart.continue") }
  given(:pay)                   { I18n.t("shop.payment.card.pay") }
  given(:completed)             { I18n.t("shop.payment.completed") }

  given(:number_id)             { "number" }
  given(:month_id)              { "exp-month" }
  given(:year_id)               { "exp-year" }
  given(:email_id)              { "confirmation_email" }
  given(:name_id)               { "payment_name" }
  given(:cvc_id)                { "cvc" }

  given(:number)                { "4242 4242 4242 4242" }
  given(:mm)                    { "01" }
  given(:yyyy)                  { (Date.today.year + 2).to_s }
  given(:cvc)                   { "123" }
  given(:force_submit)          { "\n" }

  given(:title)                 { "h3" }
  given(:refund_link)           { "Refund..." }
  given(:refund_button)         { "Refund" }
  given(:total)                 { "//th[.='All']/following-sibling::th" }
  given(:success)               { "div.alert-success" }
  given(:refund_ok)             { "Refund was successful" }

  feature "multiple items" do
    given!(:subscription_fee)  { create(:subscription_fee) }
    given!(:entry_fee)         { create(:entry_fee) }

    before(:each) do
      visit shop_path

      click_link subscription_fee.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      click_link continue
      click_link entry_fee.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      click_link checkout
      fill_in number_id, with: number
      select mm, from: month_id
      select yyyy, from: year_id
      fill_in cvc_id, with: cvc
      fill_in name_id, with: player.name
      fill_in email_id, with: player.email
      click_button pay

      expect(page).to have_css(title, text: completed)
    end

    after(:each) do
      ActionMailer::Base.deliveries.clear
    end

    it "refunded separately", js: true do
      expect(Cart.count).to eq 1
      cart = Cart.include_cartables.last
      expect(cart).to be_paid
      expect(cart.cart_items.size).to eq 2

      subscription_item = cart.cart_items.detect { |item| item.cartable_type == "Subscription" }
      entry_item = cart.cart_items.detect { |item| item.cartable_type == "Entry" }
      subscription = subscription_item.cartable
      entry = entry_item.cartable
      expect(subscription).to be_paid
      expect(entry).to be_paid

      expect(cart.total).to eq subscription.cost + entry.cost

      treasurer = login("treasurer")

      visit admin_carts_path
      click_link cart.id
      click_link refund_link

      expect(page).to have_xpath(total, text: "%.2f" % cart.total)

      check "item_#{subscription_item.id}"
      click_button refund_button
      confirm_dialog

      expect(page).to have_css(success, refund_ok)

      cart.reload
      subscription.reload
      entry.reload

      expect(cart).to be_part_refunded
      expect(cart.total).to eq entry.cost
      expect(subscription).to be_refunded
      expect(entry).to be_paid

      expect(cart.refunds.size).to eq 1
      refund = cart.refunds[0]
      expect(refund.error).to be_nil
      expect(refund.amount).to eq subscription.cost
      expect(refund.user).to eq treasurer

      click_link refund_link

      expect(page).to have_xpath(total, text: "%.2f" % cart.total)

      check "item_#{entry_item.id}"
      click_button refund_button
      confirm_dialog

      expect(page).to have_css(success, refund_ok)
      expect(page).to_not have_link(refund_button)

      cart.reload
      subscription.reload
      entry.reload

      expect(cart).to be_refunded
      expect(cart.total).to eq 0.0
      expect(subscription).to be_refunded
      expect(entry).to be_refunded

      expect(cart.refunds.size).to eq 2
      refund = cart.refunds[0]
      expect(refund.error).to be_nil
      expect(refund.amount).to eq entry.cost
      expect(refund.user).to eq treasurer
    end

    it "refunded together", js: true do
      expect(Cart.count).to eq 1
      cart = Cart.include_cartables.last
      expect(cart).to be_paid
      expect(cart.cart_items.size).to eq 2

      subscription_item = cart.cart_items.detect { |item| item.cartable_type == "Subscription" }
      entry_item = cart.cart_items.detect { |item| item.cartable_type == "Entry" }
      subscription = subscription_item.cartable
      entry = entry_item.cartable
      expect(subscription).to be_paid
      expect(entry).to be_paid

      expect(cart.total).to eq subscription.cost + entry.cost

      treasurer = login("treasurer")

      visit admin_carts_path
      click_link cart.id
      click_link refund_link

      expect(page).to have_xpath(total, text: "%.2f" % cart.total)

      check "all_items"
      click_button refund_button
      confirm_dialog

      expect(page).to have_css(success, refund_ok)

      cart.reload
      subscription.reload
      entry.reload

      expect(cart).to be_refunded
      expect(cart.total).to eq 0.0
      expect(subscription).to be_refunded
      expect(entry).to be_refunded

      expect(cart.refunds.size).to eq 1
      refund = cart.refunds[0]
      expect(refund.error).to be_nil
      expect(refund.amount).to eq subscription.cost + entry.cost
      expect(refund.user).to eq treasurer
    end
  end
end
