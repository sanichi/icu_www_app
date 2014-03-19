require 'spec_helper'

describe Fee::Subscription do
  before(:each) do
    login("treasurer")
  end

  let(:success)      { "div.alert-success" }
  let(:failure)      { "div.alert-danger" }
  let(:help)         { "div.help-block" }
  let(:name)         { I18n.t("fee.name") }
  let(:amount)       { I18n.t("fee.amount") }
  let(:clone)        { I18n.t("fee.clone") }
  let(:rollover)     { I18n.t("fee.rollover") }
  let(:type)         { I18n.t("fee.type.type") }
  let(:subscription) { I18n.t("fee.type.subscription") }
  let(:season)       { I18n.t("fee.years") }
  let(:save)         { I18n.t("save") }
  let(:edit)         { I18n.t("edit") }
  let(:delete)       { I18n.t("delete") }

  describe "create" do
    let(:fee) { create(:subscription_fee) }

    it "new" do
      visit new_admin_fee_path
      select subscription, from: type
      fill_in name, with: "Standard"
      fill_in amount, with: "35.50"
      fill_in season, with: "2013 to 2014"
      click_button save

      expect(page).to have_css(success, text: "created")

      fee = Fee::Subscription.last
      expect(fee.amount).to eq 35.5
      expect(fee.years).to eq "2013-14"
      expect(fee.sale_start.to_s).to eq "2013-08-01"
      expect(fee.sale_end.to_s).to eq "2014-08-31"
      expect(fee.journal_entries.count).to eq 1
      expect(JournalEntry.where(journalable_type: "Fee", action: "create").count).to eq 1
    end

    it "duplicate" do
      visit new_admin_fee_path
      select subscription, from: type
      fill_in name, with: fee.name
      fill_in amount, with: fee.amount
      fill_in season, with: fee.season.to_s
      click_button save

      expect(page).to have_css(help, text: "duplicate")

      fill_in season, with: fee.season.next.to_s
      click_button save

      expect(page).to have_css(success, text: "created")
    end

    it "clone" do
      visit admin_fee_path(fee)
      click_link clone
      fill_in name, with: "Unemployed"
      fill_in amount, with: "20.00"
      click_button save

      expect(page).to have_css(success, text: "created")

      expect(Fee::Subscription.count).to eq 2
      expect(Fee::Subscription.first.season).to eq Fee::Subscription.last.season
      expect(JournalEntry.where(journalable_type: "Fee", action: "create").count).to eq 1
    end

    it "rollover" do
      visit admin_fee_path(fee)
      click_link rollover
      click_button save

      expect(page).to have_css(success, text: "created")

      expect(Fee::Subscription.count).to eq 2
      expect(Fee::Subscription.first.season.next).to eq Fee::Subscription.last.season
      expect(JournalEntry.where(journalable_type: "Fee", action: "create").count).to eq 1

      visit admin_fee_path(fee)
      expect(page).not_to have_button(rollover)

      visit rollover_admin_fee_path(fee)
      expect(page).to have_css(failure, text: "can't be rolled over")
    end
  end

  describe "edit" do
    let(:fee) { create(:subscription_fee) }

    it "amount" do
      visit admin_fee_path(fee)
      click_link edit
      fill_in amount, with: " 9999.99 "
      click_button save

      fee.reload
      expect(fee.amount).to eq 9999.99

      expect(JournalEntry.where(journalable_type: "Fee", action: "update").count).to eq 1
    end
  end

  describe "delete" do
    let(:fee) { create(:subscription_fee, name: "Special") }
    let(:item) { create(:subscription_item) }

    it "without items" do
      visit admin_fee_path(fee)
      click_link delete

      expect(page).to have_css(success, text: /successfully deleted/)

      expect(Fee::Subscription.count).to eq 0
      expect(JournalEntry.where(journalable_type: "Fee", action: "destroy").count).to eq 1
    end

    it "with items" do
      visit admin_fee_path(item.fee)
      expect(page).to_not have_link(delete)

      visit admin_fee_path(item.fee, show_delete_button_for_test: "")
      click_link delete

      expect(page).to have_css(failure, text: /can't be deleted/)
      expect(Fee::Subscription.count).to eq 1
      expect(Item::Subscription.count).to eq 1
      expect(JournalEntry.where(journalable_type: "Fee", action: "destroy").count).to eq 0

      item.fee.items.each { |item| item.destroy }

      visit admin_fee_path(item.fee)
      click_link delete

      expect(page).to have_css(success, text: /successfully deleted/)

      expect(Fee::Subscription.count).to eq 0
      expect(Item::Subscription.count).to eq 0
      expect(JournalEntry.where(journalable_type: "Fee", action: "destroy").count).to eq 1
    end
  end
end
