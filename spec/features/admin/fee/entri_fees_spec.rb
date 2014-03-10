require 'spec_helper'

describe Fee::Entri do
  before(:each) do
    login("treasurer")
  end

  let(:success)           { "div.alert-success" }
  let(:failure)           { "div.alert-danger" }
  let(:help)              { "div.help-block" }
  let(:type)              { I18n.t("fee.type.type") }
  let(:entry)             { I18n.t("fee.type.entry") }
  let(:clone)             { I18n.t("fee.clone") }
  let(:rollover)          { I18n.t("fee.rollover") }
  let(:name)              { I18n.t("fee.name") }
  let(:amount)            { I18n.t("fee.amount") }
  let(:start_date)        { I18n.t("fee.start") }
  let(:end_date)          { I18n.t("fee.end") }
  let(:sale_start)        { I18n.t("fee.sale_start") }
  let(:sale_end)          { I18n.t("fee.sale_end") }
  let(:discounted_amount) { I18n.t("fee.discounted_amount") }
  let(:discount_deadline) { I18n.t("fee.discount_deadline") }
  let(:min_rating)        { I18n.t("fee.rating.min") }
  let(:max_rating)        { I18n.t("fee.rating.max") }
  let(:min_age)           { I18n.t("fee.age.min") }
  let(:max_age)           { I18n.t("fee.age.max") }
  let(:age_ref)           { I18n.t("fee.age.ref_date") }
  let(:save)              { I18n.t("save") }
  let(:edit)              { I18n.t("edit") }
  let(:delete)            { I18n.t("delete") }
  let(:last_week)         { Date.today.days_ago(7) }
  let(:next_year)         { Date.today.at_end_of_year.days_since(40) }
  let(:week_ago)          { Date.today.days_ago(7) }
  let(:late_next_year)    { Date.today.next_year.at_end_of_year.days_ago(1) }

  describe "create" do
    let(:fee) { create(:entri_fee) }

    it "new" do
      visit new_admin_fee_path
      select entry, from: type
      fill_in name, with: "Bunratty Masters"
      fill_in amount, with: "50"
      fill_in start_date, with: next_year.to_s
      fill_in end_date, with: next_year.days_since(2).to_s
      fill_in sale_start, with: last_week.to_s
      fill_in sale_end, with: next_year.to_s
      click_button save

      expect(page).to have_css(success, text: "created")

      fee = Fee::Entri.last
      expect(fee.name).to eq "Bunratty Masters"
      expect(fee.amount).to eq 50.0
      expect(fee.discounted_amount).to be_nil
      expect(fee.discount_deadline).to be_nil
      expect(fee.start_date).to eq next_year
      expect(fee.end_date).to eq next_year.days_since(2)
      expect(fee.sale_start).to eq last_week
      expect(fee.sale_end).to eq next_year
      expect(fee.year).to eq next_year.year
      expect(fee.years).to be_nil
      expect(fee.min_rating).to be_nil
      expect(fee.max_rating).to be_nil
      expect(fee.min_age).to be_nil
      expect(fee.max_age).to be_nil
      expect(fee.age_ref_date).to be_nil
      expect(fee.journal_entries.count).to eq 1
      expect(JournalEntry.where(journalable_type: "Fee", action: "create").count).to eq 1
    end

    it "duplicate" do
      fee = create(:entri_fee)

      visit new_admin_fee_path
      select entry, from: type
      fill_in name, with: fee.name
      fill_in amount, with: fee.amount.to_s
      fill_in start_date, with: fee.start_date.to_s
      fill_in end_date, with: fee.end_date.to_s
      fill_in sale_start, with: fee.sale_start.to_s
      fill_in sale_end, with: fee.sale_end.to_s
      click_button save

      expect(page).to have_css(help, text: "duplicate")

      fill_in start_date, with: fee.start_date.years_since(1).to_s
      fill_in end_date, with: fee.end_date.years_since(1).to_s
      fill_in sale_start, with: fee.sale_start.years_since(1).to_s
      fill_in sale_end, with: fee.sale_end.years_since(1).to_s
      click_button save

      expect(page).to have_css(success, text: "created")
    end

    it "clone" do
      expect(fee).to be_cloneable
      visit admin_fee_path(fee)
      click_link clone
      fill_in name, with: "Bunratty Challengers"
      fill_in amount, with: "20.00"
      click_button save

      expect(page).to have_css(success, text: "created")

      expect(Fee::Entri.count).to eq 2
      expect(JournalEntry.where(journalable_type: "Fee", action: "create").count).to eq 1
    end

    it "rollover" do
      visit admin_fee_path(fee)
      click_link rollover
      click_button save

      expect(page).to have_css(success, text: "created")

      expect(Fee::Entri.count).to eq 2
      expect(JournalEntry.where(journalable_type: "Fee", action: "create").count).to eq 1

      visit admin_fee_path(fee)
      expect(page).not_to have_button(rollover)

      visit rollover_admin_fee_path(fee)
      expect(page).to have_css(failure, text: "can't be rolled over")
    end

    it "discount, rating and age" do
      visit new_admin_fee_path
      select entry, from: type
      fill_in name, with: "Bangor U12"
      fill_in amount, with: "35"
      fill_in discounted_amount, with: "30"
      fill_in discount_deadline, with: late_next_year.days_ago(10).to_s
      fill_in start_date, with: late_next_year.to_s
      fill_in end_date, with: late_next_year.days_since(5).to_s
      fill_in sale_start, with: last_week
      fill_in sale_end, with: late_next_year.days_ago(1)
      fill_in min_rating, with: "1500"
      fill_in max_rating, with: "2000"
      fill_in min_age, with: "10"
      fill_in max_age, with: "12"
      fill_in age_ref, with: late_next_year.to_s
      click_button save

      expect(page).to have_css(success, text: "created")

      fee = Fee::Entri.last
      expect(fee.name).to eq "Bangor U12"
      expect(fee.amount).to eq 35.0
      expect(fee.discounted_amount).to eq 30.0
      expect(fee.discount_deadline).to eq late_next_year.days_ago(10)
      expect(fee.start_date).to eq late_next_year
      expect(fee.end_date).to eq late_next_year.days_since(5)
      expect(fee.sale_start).to eq last_week
      expect(fee.sale_end).to eq late_next_year.days_ago(1)
      expect(fee.year).to be_nil
      expect(fee.years).to eq Season.new(late_next_year).to_s
      expect(fee.min_rating).to eq 1500
      expect(fee.max_rating).to eq 2000
      expect(fee.min_age).to eq 10
      expect(fee.max_age).to eq 12
      expect(fee.age_ref_date).to eq late_next_year
      expect(fee.journal_entries.count).to eq 1
      expect(JournalEntry.where(journalable_type: "Fee", action: "create").count).to eq 1
    end

    it "bad age" do
      visit new_admin_fee_path
      select entry, from: type
      fill_in name, with: "Leinster U15"
      fill_in amount, with: "30"
      fill_in start_date, with: next_year.to_s
      fill_in end_date, with: next_year.days_since(2).to_s
      fill_in min_age, with: "14"
      fill_in max_age, with: "15"
      click_button save

      expect(page).to have_css(help, text: "reference date")

      fill_in min_age, with: "16"
      fill_in age_ref, with: next_year.to_s
      click_button save

      expect(page).to have_css(failure, text: "greater")

      fill_in min_age, with: ""
      click_button save

      expect(page).to have_css(success, text: "created")
    end

    it "bad rating" do
      visit new_admin_fee_path
      select entry, from: type
      fill_in name, with: "Bunratty Challengers"
      fill_in amount, with: "30"
      fill_in start_date, with: next_year.to_s
      fill_in end_date, with: next_year.days_since(2).to_s
      fill_in min_rating, with: "2000"
      fill_in max_rating, with: "1000"
      click_button save

      expect(page).to have_css(failure, text: "greater than")

      fill_in min_rating, with: "1500"
      fill_in max_rating, with: "1500"
      click_button save

      expect(page).to have_css(failure, text: "too close")

      fill_in min_rating, with: "1400"
      fill_in max_rating, with: "1600"
      click_button save

      expect(page).to have_css(success, text: "created")
    end
  end

  describe "edit" do
    let(:fee) { create(:entri_fee, name: "Bunratty Masters") }

    it "amount" do
      visit admin_fee_path(fee)
      click_link edit
      fill_in amount, with: "99"
      click_button save

      fee.reload
      expect(fee.amount).to eq 99.0

      expect(JournalEntry.where(journalable_type: "Fee", action: "update").count).to eq 1
    end
  end

  describe "delete" do
    let(:fee) { create(:entri_fee, name: "Bunratty Special") }
    let(:item) { create(:entri_item) }

    it "without items" do
      visit admin_fee_path(fee)
      click_link delete

      expect(page).to have_css(success, text: /successfully deleted/)

      expect(Fee::Entri.count).to eq 0
      expect(JournalEntry.where(journalable_type: "Fee", action: "destroy").count).to eq 1
    end

    it "with items" do
      visit admin_fee_path(item.fee)
      expect(page).to_not have_link(delete)

      visit admin_fee_path(item.fee, show_delete_button_for_test: "")
      click_link delete

      expect(page).to have_css(failure, text: /can't be deleted/)
      expect(Fee::Entri.count).to eq 1
      expect(Item::Entri.count).to eq 1
      expect(JournalEntry.where(journalable_type: "Fee", action: "destroy").count).to eq 0

      item.fee.items.each { |item| item.destroy }

      visit admin_fee_path(item.fee)
      click_link delete

      expect(page).to have_css(success, text: /successfully deleted/)

      expect(Fee::Entri.count).to eq 0
      expect(Item::Entri.count).to eq 0
      expect(JournalEntry.where(journalable_type: "Fee", action: "destroy").count).to eq 1
    end
  end
end
