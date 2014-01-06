require 'spec_helper'

feature "Authorization for entry fees" do
  given(:player)          { create(:player) }
  given(:user)            { create(:user, player: player) }
  given(:fee)             { create(:entry_fee, player: user.player) }
  given(:ok_roles)        { %w[admin treasurer] }
  given(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) } }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:button)          { I18n.t("edit") }
  given(:unauthorized)    { I18n.t("errors.messages.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }
  given(:paths)           { [admin_entry_fees_path, new_admin_entry_fee_path, admin_entry_fee_path(fee), edit_admin_entry_fee_path(fee)] }

  scenario "the admin and treasurer roles can manage entry fees" do
    ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      paths.each do |path|
        visit path
        expect(page).to_not have_css(failure)
      end
    end
  end

  scenario "the contact can only view entry fees" do
    login user
    expect(page).to have_css(success, text: signed_in_as)
    paths.each_with_index do |path, i|
      visit path
      if [0, 1, 3].include?(i)
        expect(page).to have_css(failure, text: unauthorized)
      else
        expect(page).to_not have_css(failure)
      end
    end
  end

  scenario "other roles have no access" do
    not_ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      paths.each do |path|
        visit path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end

  scenario "guests have no access" do
    logout
    paths.each do |path|
      visit path
      expect(page).to have_css(failure, text: unauthorized)
    end
  end
end

feature "Create and delete an entry fee" do
  before(:each) do
    login("treasurer")
  end

  given(:success)           { "div.alert-success" }
  given(:failure)           { "div.alert-danger" }
  given(:attr_failure)      { "div.help-block" }
  given(:amount)            { I18n.t("fee.amount") }
  given(:discounted_amount) { I18n.t("fee.discounted_amount") }
  given(:discount_deadline) { I18n.t("fee.discount_deadline") }
  given(:event_name)        { I18n.t("fee.entry.event.name") }
  given(:event_start)       { I18n.t("fee.entry.event.start") }
  given(:event_end)         { I18n.t("fee.entry.event.end") }
  given(:select_contact)    { I18n.t("fee.entry.select_contact") }
  given(:reselect_contact)  { I18n.t("fee.entry.reselect_contact") }
  given(:min_rating)        { I18n.t("fee.entry.min_rating") }
  given(:max_rating)        { I18n.t("fee.entry.max_rating") }
  given(:sale_start)        { I18n.t("fee.sale_start") }
  given(:sale_end)          { I18n.t("fee.sale_end") }
  given(:first_name)        { I18n.t("player.first_name") }
  given(:last_name)         { I18n.t("player.last_name") }
  given(:delete)            { I18n.t("delete") }
  given(:save)              { I18n.t("save") }
  given(:last_week)         { Date.today.days_ago(7) }
  given(:next_year)         { Date.today.at_end_of_year.days_since(40) }
  given(:late_next_year)    { Date.today.next_year.at_end_of_year.days_ago(1) }
  given(:user)              { create(:user) }
  given(:user_expired)      { create(:user, expires_on: Date.today.last_year.at_end_of_year) }
  given(:user_no_email)     { create(:user, player: create(:player,email: nil)) }
  given(:player_no_user)    { create(:player) }

  scenario "no frills" do
    visit new_admin_entry_fee_path
    fill_in event_name, with: "Bunratty Masters"
    fill_in amount, with: "50"
    fill_in event_start, with: next_year.to_s
    fill_in event_end, with: next_year.days_since(2).to_s
    fill_in sale_start, with: last_week
    fill_in sale_end, with: next_year.days_ago(1)
    click_button save

    expect(page).to have_css(success, text: "created")

    fee = EntryFee.last
    expect(fee.event_name).to eq "Bunratty Masters"
    expect(fee.amount).to eq 50.0
    expect(fee.discounted_amount).to be_nil
    expect(fee.discount_deadline).to be_nil
    expect(fee.event_start).to eq next_year
    expect(fee.event_end).to eq next_year.days_since(2)
    expect(fee.sale_start).to eq last_week
    expect(fee.sale_end).to eq next_year.days_ago(1)
    expect(fee.year_or_season).to eq next_year.year.to_s
    expect(fee.min_rating).to be_nil
    expect(fee.max_rating).to be_nil
    expect(fee.journal_entries.count).to eq 1
    expect(JournalEntry.where(journalable_type: "EntryFee").count).to eq 1

    click_link delete
    expect(EntryFee.count).to eq 0
    expect(JournalEntry.where(journalable_type: "EntryFee").count).to eq 2
  end

  scenario "with discount and rating constraints" do
    visit new_admin_entry_fee_path
    fill_in event_name, with: "Bangor Xmas Special"
    fill_in amount, with: "35"
    fill_in discounted_amount, with: "30"
    fill_in discount_deadline, with: late_next_year.days_ago(10).to_s
    fill_in event_start, with: late_next_year.to_s
    fill_in event_end, with: late_next_year.days_since(5).to_s
    fill_in sale_start, with: last_week
    fill_in sale_end, with: late_next_year.days_ago(1)
    fill_in min_rating, with: "1500"
    fill_in max_rating, with: "2000"
    click_button save

    expect(page).to have_css(success, text: "created")

    fee = EntryFee.last
    expect(fee.event_name).to eq "Bangor Xmas Special"
    expect(fee.amount).to eq 35.0
    expect(fee.discounted_amount).to eq 30.0
    expect(fee.discount_deadline).to eq late_next_year.days_ago(10)
    expect(fee.event_start).to eq late_next_year
    expect(fee.event_end).to eq late_next_year.days_since(5)
    expect(fee.sale_start).to eq last_week
    expect(fee.sale_end).to eq late_next_year.days_ago(1)
    expect(fee.year_or_season).to eq Season.new(late_next_year).desc
    expect(fee.min_rating).to eq 1500
    expect(fee.max_rating).to eq 2000
    expect(fee.journal_entries.count).to eq 1
    expect(JournalEntry.where(journalable_type: "EntryFee").count).to eq 1

    click_link delete
    expect(EntryFee.count).to eq 0
    expect(JournalEntry.where(journalable_type: "EntryFee").count).to eq 2
  end

  scenario "with contact", js: true do
    visit new_admin_entry_fee_path
    fill_in event_name, with: "Bunratty Masters"
    fill_in amount, with: "50"
    fill_in event_start, with: next_year.to_s
    fill_in event_end, with: next_year.days_since(2).to_s
    fill_in sale_start, with: last_week
    fill_in sale_end, with: next_year.days_ago(1)

    click_button select_contact
    fill_in last_name, with: player_no_user.last_name
    fill_in first_name, with: player_no_user.first_name + "\n"
    click_link player_no_user.id
    click_button save

    expect(page).to have_css(failure, text: /no login/)

    click_button reselect_contact
    fill_in last_name, with: user_no_email.player.last_name
    fill_in first_name, with: user_no_email.player.first_name + "\n"
    click_link user_no_email.player.id
    click_button save

    expect(page).to have_css(failure, text: /no email/)

    click_button reselect_contact
    fill_in last_name, with: user_expired.player.last_name
    fill_in first_name, with: user_expired.player.first_name + "\n"
    click_link user_expired.player.id
    click_button save

    expect(page).to have_css(failure, text: /current member/)

    click_button reselect_contact
    fill_in last_name, with: user.player.last_name
    fill_in first_name, with: user.player.first_name + "\n"
    click_link user.player.id
    click_button save

    expect(page).to have_css(success, text: "created")

    fee = EntryFee.last
    expect(fee.player).to eq user.player

    click_link delete
    confirm_dialog
    expect(EntryFee.count).to eq 0
    expect(JournalEntry.where(journalable_type: "EntryFee").count).to eq 2
  end

  scenario "duplicate" do
    fee = create(:entry_fee)

    visit new_admin_entry_fee_path
    fill_in event_name, with: fee.event_name
    fill_in amount, with: fee.amount.to_s
    fill_in event_start, with: fee.event_start.to_s
    fill_in event_end, with: fee.event_end.to_s
    fill_in sale_start, with: fee.sale_start.to_s
    fill_in sale_end, with: fee.sale_end.to_s
    click_button save

    expect(page).to have_css(attr_failure, text: "one per year/season")

    fill_in event_start, with: fee.event_start.years_since(1).to_s
    fill_in event_end, with: fee.event_end.years_since(1).to_s
    fill_in sale_start, with: fee.sale_start.years_since(1).to_s
    fill_in sale_end, with: fee.sale_end.years_since(1).to_s
    click_button save

    expect(page).to have_css(success, text: "created")
  end
end

feature "Edit an entry fee" do
  before(:each) do
    login("treasurer")
  end

  given(:fee)         { create(:entry_fee, event_name: "Bunratty Masters") }
  given(:amount)      { I18n.t("fee.amount") }
  given(:event_name)  { I18n.t("fee.entry.event.name") }
  given(:clone)       { I18n.t("fee.clone") }
  given(:rollover)    { I18n.t("fee.rollover") }
  given(:edit)        { I18n.t("edit") }
  given(:save)        { I18n.t("save") }
  given(:success)     { "div.alert-success" }
  given(:description) { "//th[.='#{I18n.t("fee.description")}']/following-sibling::td" }

  scenario "update amount" do
    visit admin_entry_fee_path(fee)
    click_link edit
    fill_in amount, with: "99"
    click_button save

    fee = EntryFee.last
    expect(fee.amount).to eq 99.0
  end

  scenario "rollover" do
    expect(JournalEntry.count).to eq 0

    visit admin_entry_fee_path(fee)
    click_link rollover
    click_button save

    expect(page).to have_css(success, text: "created")
    expect(page).to have_xpath(description, text: "#{fee.event_name} #{fee.year_or_season.to_i + 1}")

    fee2 = EntryFee.last
    expect(fee2.event_name).to eq fee.event_name
    expect(fee2.amount).to eq fee.amount
    expect(fee2.event_website).to eq fee.event_website
    expect(fee2.player_id).to eq fee.player_id
    expect(fee2.event_start).to eq fee.event_start.years_since(1)
    expect(fee2.event_end).to eq fee.event_end.years_since(1)
    expect(fee2.sale_start).to eq fee.sale_start.years_since(1)
    expect(fee2.sale_end).to eq fee.sale_end.years_since(1)
    expect(fee2.discounted_amount).to eq fee.discounted_amount
    if fee.discount_deadline.present?
      expect(fee2.discount_deadline).to eq fee.discount_deadline.years_since(1)
    else
      expect(fee2.discount_deadline).to be_nil
    end

    expect(JournalEntry.where(action: "create").count).to eq 1
  end

  scenario "clone" do
    expect(JournalEntry.count).to eq 0

    visit admin_entry_fee_path(fee)
    click_link clone

    fill_in event_name, with: "Bunratty Challengers"
    fill_in amount, with: "20"
    click_button save

    expect(page).to have_css(success, text: "created")

    clone = EntryFee.last
    expect(clone.event_name).to eq "Bunratty Challengers"
    expect(clone.amount).to eq 20.0
    %w[discounted_amount discount_deadline event_start event_end sale_start sale_end year_or_season].each do |atr|
      expect(clone.send(atr)).to eq fee.send(atr)
    end

    expect(JournalEntry.where(action: "create", journalable_type: "EntryFee", journalable_id: clone.id).count).to eq 1
  end
end
