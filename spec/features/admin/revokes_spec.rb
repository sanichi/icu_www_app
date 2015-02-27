require 'rails_helper'

describe "Revoke", js: true do
  include_context "features"

  let(:add_to_cart)       { I18n.t("item.add") }
  let(:cheque)            { I18n.t("shop.payment.method.cheque") }
  let(:continue)          { I18n.t("shop.cart.continue") }
  let(:first_name)        { I18n.t("player.first_name") }
  let(:last_name)         { I18n.t("player.last_name") }
  let(:method)            { I18n.t("shop.payment.method.method") }
  let(:pay)               { I18n.t("shop.payment.card.pay") }
  let(:pr_email)          { I18n.t("shop.payment.offline.email") }
  let(:pr_first_name)     { I18n.t("shop.payment.offline.first_name") }
  let(:pr_last_name)      { I18n.t("shop.payment.offline.last_name") }
  let(:received)          { I18n.t("shop.payment.received") }
  let(:refund_button)     { I18n.t("shop.payment.refund") }
  let(:registered)        { I18n.t("shop.payment.registered") }
  let(:revoke_button)     { I18n.t("shop.payment.revoke") }
  let(:select_member)     { I18n.t("item.member.select") }

  let(:revoke_link)       { "#{revoke_button}..." }
  let(:revoke_ok)         { "#{revoke_button} was successful" }
  let(:total)             { "//th[.='All']/following-sibling::th" }

  let(:player)            { create(:player) }
  let!(:subscription_fee) { create(:subscription_fee) }

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  context "multiple items" do
    let!(:entry_fee) { create(:entry_fee) }

    before(:each) do
      @treasurer = login("treasurer")
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

      click_link received
      fill_in pr_first_name, with: player.first_name
      fill_in pr_last_name, with: player.last_name
      select cheque, from: method
      fill_in pr_email, with: player.email
      click_button confirm

      expect(page).to have_css(success, text: registered)
    end

    it "revoke separately" do
      expect(Cart.count).to eq 1
      cart = Cart.include_items.last
      expect(cart).to be_paid
      expect(cart.items.size).to eq 2

      subscription = cart.items.detect { |item| item.type == "Item::Subscription" }
      entry = cart.items.detect { |item| item.type == "Item::Entry" }
      expect(subscription).to be_paid
      expect(entry).to be_paid

      expect(cart.total).to eq subscription.cost + entry.cost

      visit admin_carts_path
      click_link cart.id
      click_link revoke_link

      expect(page).to have_xpath(total, text: "%.2f" % cart.total)

      check "item_#{subscription.id}"
      click_button revoke_button
      confirm_dialog

      expect(page).to have_css(success, revoke_ok)

      cart.reload
      subscription.reload
      entry.reload

      expect(cart).to be_part_refunded
      expect(cart.total).to eq entry.cost
      expect(subscription).to be_refunded
      expect(entry).to be_paid

      expect(cart.refunds.size).to eq 1
      refund = cart.refunds.last
      expect(refund.error).to be_nil
      expect(refund.amount).to eq subscription.cost
      expect(refund.user).to eq @treasurer
      expect(refund.automatic).to be false

      click_link revoke_link

      expect(page).to have_xpath(total, text: "%.2f" % cart.total)

      check "item_#{entry.id}"
      click_button revoke_button
      confirm_dialog

      expect(page).to have_css(success, revoke_ok)
      expect(page).to_not have_link(revoke_button)
      expect(page).to_not have_link(refund_button)

      cart.reload
      subscription.reload
      entry.reload

      expect(cart).to be_refunded
      expect(cart.total).to eq 0.0
      expect(subscription).to be_refunded
      expect(entry).to be_refunded

      expect(cart.refunds.size).to eq 2
      refund = cart.refunds.where.not(id: refund.id).first
      expect(refund.error).to be_nil
      expect(refund.amount).to eq entry.cost
      expect(refund.user).to eq @treasurer
      expect(refund.automatic).to be false
    end

    it "revoked together" do
      expect(Cart.count).to eq 1
      cart = Cart.include_items.last
      expect(cart).to be_paid
      expect(cart.items.size).to eq 2

      subscription = cart.items.detect { |item| item.type == "Item::Subscription" }
      entry = cart.items.detect { |item| item.type == "Item::Entry" }
      expect(subscription).to be_paid
      expect(entry).to be_paid

      expect(cart.total).to eq subscription.cost + entry.cost

      visit admin_carts_path
      click_link cart.id
      click_link revoke_link

      expect(page).to have_xpath(total, text: "%.2f" % cart.total)

      check "all_items"
      click_button revoke_button
      confirm_dialog

      expect(page).to have_css(success, revoke_ok)
      expect(page).to_not have_link(revoke_button)
      expect(page).to_not have_link(refund_button)

      cart.reload
      subscription.reload
      entry.reload

      expect(cart).to be_refunded
      expect(cart.total).to eq 0.0
      expect(subscription).to be_refunded
      expect(entry).to be_refunded

      expect(cart.refunds.size).to eq 1
      refund = cart.refunds.last
      expect(refund.error).to be_nil
      expect(refund.amount).to eq subscription.cost + entry.cost
      expect(refund.user).to eq @treasurer
      expect(refund.automatic).to be false
    end
  end
end
