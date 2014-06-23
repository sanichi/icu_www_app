require 'rails_helper'

describe Refund do;
  include_context "features"

  let(:add_to_cart)           { I18n.t("item.add") }
  let(:checkout)              { I18n.t("shop.cart.checkout") }
  let(:completed)             { I18n.t("shop.payment.completed") }
  let(:continue)              { I18n.t("shop.cart.continue") }
  let(:first_name)            { I18n.t("player.first_name") }
  let(:last_name)             { I18n.t("player.last_name") }
  let(:pay)                   { I18n.t("shop.payment.card.pay") }
  let(:select_member)         { I18n.t("item.member.select") }

  let(:cvc_id)                { "cvc" }
  let(:email_id)              { "confirmation_email" }
  let(:expiry_id)             { "expiry" }
  let(:name_id)               { "payment_name" }
  let(:number_id)             { "number" }

  let(:cvc)                   { "123" }
  let(:expiry)                { "01 / #{(Date.today.year + 2).to_s}" }
  let(:number)                { "4242 4242 4242 4242" }

  let(:refund_button)         { "Refund" }
  let(:refund_link)           { "Refund..." }
  let(:refund_ok)             { "Refund was successful" }
  let(:title)                 { "h3" }
  let(:total)                 { "//th[.='All']/following-sibling::th" }

  let(:player)                { create(:player) }

  context "multiple items" do
    let!(:subscription_fee)  { create(:subscription_fee) }
    let!(:entry_fee)         { create(:entry_fee) }

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
      fill_in expiry_id, with: expiry
      fill_in cvc_id, with: cvc
      fill_in name_id, with: player.name
      fill_in email_id, with: player.email
      click_button pay

      expect(page).to have_css(title, text: completed)
    end

    after(:each) do
      ActionMailer::Base.deliveries.clear
    end

    it "refund separately", js: true do
      expect(Cart.count).to eq 1
      cart = Cart.include_items.last
      expect(cart).to be_paid
      expect(cart.items.size).to eq 2

      subscription = cart.items.detect { |item| item.type == "Item::Subscription" }
      entry = cart.items.detect { |item| item.type == "Item::Entry" }
      expect(subscription).to be_paid
      expect(entry).to be_paid

      expect(cart.total).to eq subscription.cost + entry.cost

      treasurer = login("treasurer")

      visit admin_carts_path
      click_link cart.id
      click_link refund_link

      expect(page).to have_xpath(total, text: "%.2f" % cart.total)

      check "item_#{subscription.id}"
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

      check "item_#{entry.id}"
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
      cart = Cart.include_items.last
      expect(cart).to be_paid
      expect(cart.items.size).to eq 2

      subscription = cart.items.detect { |item| item.type == "Item::Subscription" }
      entry = cart.items.detect { |item| item.type == "Item::Entry" }
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
