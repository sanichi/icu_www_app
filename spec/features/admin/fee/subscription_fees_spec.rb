require 'spec_helper'

describe Fee::Subscription do
  include_context "features"

  let(:amount)       { I18n.t("fee.amount") }
  let(:clone)        { I18n.t("fee.clone") }
  let(:fee_name)     { I18n.t("fee.name") }
  let(:rollover)     { I18n.t("fee.rollover") }
  let(:subscription) { I18n.t("fee.type.subscription") }

  before(:each) do
    login("treasurer")
  end

  context "create" do
    let(:fee) { create(:subscription_fee) }

    it "new" do
      visit new_admin_fee_path
      click_link subscription
      fill_in name, with: "Standard"
      fill_in amount, with: "35.50"
      fill_in season, with: "2013 to 2014"
      check active
      click_button save

      expect(page).to have_css(success, text: "created")

      fee = Fee::Subscription.last
      expect(fee.amount).to eq 35.5
      expect(fee.years).to eq "2013-14"
      expect(fee.sale_start.to_s).to eq "2013-08-01"
      expect(fee.sale_end.to_s).to eq "2014-08-31"
      expect(fee.journal_entries.count).to eq 1
      expect(fee.active).to be_true
      expect(JournalEntry.where(journalable_type: "Fee", action: "create").count).to eq 1
    end

    it "duplicate" do
      visit new_admin_fee_path
      click_link subscription
      fill_in fee_name, with: fee.name
      fill_in amount, with: fee.amount
      fill_in season, with: fee.season.to_s
      click_button save

      expect(page).to have_css(field_error, text: "duplicate")

      fill_in season, with: fee.season.next.to_s
      click_button save

      expect(page).to have_css(success, text: "created")
    end

    it "clone" do
      visit admin_fee_path(fee)
      click_link clone
      fill_in fee_name, with: "Unemployed"
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

  context "edit" do
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

    it "active" do
      visit admin_fee_path(fee)
      click_link edit
      uncheck active
      click_button save

      fee.reload
      expect(fee.active).to be_false

      expect(JournalEntry.where(journalable_type: "Fee", action: "update").count).to eq 1
    end
  end

  context "delete" do
    let(:fee) { create(:subscription_fee, name: "Special") }
    let(:item) { create(:subscription_item) }

    it "without items" do
      visit admin_fee_path(fee)
      click_link delete

      expect(page).to have_css(success, text: "deleted")

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

      expect(page).to have_css(success, text: "deleted")

      expect(Fee::Subscription.count).to eq 0
      expect(Item::Subscription.count).to eq 0
      expect(JournalEntry.where(journalable_type: "Fee", action: "destroy").count).to eq 1
    end
  end
end
