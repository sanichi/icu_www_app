require 'spec_helper'

feature "Authorization for subscription fees" do
  given(:ok_roles)        { %w[admin treasurer] }
  given(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) } }
  given(:fee)             { create(:subscription_fee) }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:button)          { I18n.t("edit") }
  given(:unauthorized)    { I18n.t("errors.messages.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }
  given(:paths)           { [new_admin_subscription_fee_path, edit_admin_subscription_fee_path(fee), admin_subscription_fees_path, admin_subscription_fee_path(fee)] }

  scenario "some roles can manage subscription fees" do
    ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      paths.each do |path|
        visit path
        expect(page).to_not have_css(failure)
      end
    end
  end

  scenario "other roles and guests have no access" do
    not_ok_roles.push("guest").each do |role|
      if role == "guest"
        logout
      else
        login role
        expect(page).to have_css(success, text: signed_in_as)
      end
      paths.each do |path|
        visit path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end
end

feature "Create and delete a subscription" do
  before(:each) do
    login("treasurer")
  end

  given(:success)  { "div.alert-success" }
  given(:failure)  { "div.help-block" }
  given(:amount)   { I18n.t("fee.amount") }
  given(:category) { I18n.t("fee.subscription.category.category") }
  given(:standard) { I18n.t("fee.subscription.category.standard") }
  given(:season)   { I18n.t("fee.subscription.season") }
  given(:save)     { I18n.t("save") }
  given(:delete)   { I18n.t("delete") }
  given(:fee)      { create(:subscription_fee) }

  scenario "standard" do
    visit new_admin_subscription_fee_path
    select standard, from: category
    fill_in amount, with: "35.50"
    fill_in season, with: "2013 to 2014"
    click_button save

    expect(page).to have_css(success, text: "created")

    fee = SubscriptionFee.last
    expect(fee.category).to eq "standard"
    expect(fee.amount).to eq 35.5
    expect(fee.season_desc).to eq "2013-14"
    expect(fee.sale_start.to_s).to eq "2013-08-01"
    expect(fee.sale_end.to_s).to eq "2014-08-31"
    expect(fee.journal_entries.count).to eq 1
    expect(JournalEntry.where(journalable_type: "SubscriptionFee").count).to eq 1

    click_link delete
    expect(SubscriptionFee.count).to eq 0
    expect(JournalEntry.where(journalable_type: "SubscriptionFee").count).to eq 2
  end

  scenario "duplicate" do
    visit new_admin_subscription_fee_path
    select I18n.t("fee.subscription.category.#{fee.category}"), from: category
    fill_in season, with: fee.season_desc
    fill_in amount, with: fee.amount
    click_button save

    expect(page).to have_css(failure, text: "one per season")

    fill_in season, with: fee.season.next.to_s
    click_button save

    expect(page).to have_css(success, text: "created")
  end
end

feature "Edit a subscription fee" do
  before(:each) do
    login("treasurer")
  end

  given(:fee)      { create(:subscription_fee) }
  given(:edit)     { I18n.t("edit") }
  given(:save)     { I18n.t("save") }
  given(:amount)   { I18n.t("fee.amount") }
  given(:rollover) { I18n.t("fee.rollover") }
  given(:success)  { "div.alert-success" }
  given(:season)   { "//th[.='#{I18n.t("fee.subscription.season")}']/following-sibling::td" }

  scenario "update amount" do
    visit admin_subscription_fee_path(fee)
    click_link edit
    fill_in amount, with: " 9999.99 "
    click_button save

    fee = SubscriptionFee.last
    expect(fee.amount).to eq 9999.99
  end

  scenario "rollover" do
    expect(JournalEntry.count).to eq 0

    visit admin_subscription_fee_path(fee)
    click_link rollover

    expect(page).to have_css(success, text: "rolled over")
    expect(page).to have_xpath(season, text: fee.season.next.to_s)
    expect(page).to_not have_link(rollover)

    expect(JournalEntry.where(action: "create").count).to eq 1
  end
end

feature "Subscription fees linked to subscriptions" do
  before(:each) do
    login("treasurer")
  end

  given(:player)        { create(:player) }
  given(:fee)           { create(:subscription_fee) }
  given!(:subscription) { create(:subscription, subscription_fee: fee, player: player) }
  given(:delete)        { I18n.t("delete") }
  given(:success)       { "div.alert-success" }
  given(:failure)       { "div.alert-danger" }

  scenario "can't be deleted" do
    expect(SubscriptionFee.count).to eq 1
    expect(Subscription.count).to eq 1

    visit admin_subscription_fee_path(fee)
    expect(page).to_not have_link(delete)

    visit admin_subscription_fee_path(fee, show_delete_button_for_test: "")
    click_link delete

    expect(page).to have_css(failure, text: /can't be deleted/)
    expect(SubscriptionFee.count).to eq 1
    expect(Subscription.count).to eq 1

    fee.subscriptions.each { |sub| sub.destroy }
    expect(SubscriptionFee.count).to eq 1
    expect(Subscription.count).to eq 0

    visit admin_subscription_fee_path(fee)
    click_link delete

    expect(page).to have_css(success, text: /successfully deleted/)
    expect(SubscriptionFee.count).to eq 0
    expect(Subscription.count).to eq 0
  end
end
