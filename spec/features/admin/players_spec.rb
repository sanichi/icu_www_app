# encoding: utf-8
require 'spec_helper'

feature "Authorization for players" do
  given(:ok_roles)        { %w[admin membership] }
  given(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) } }
  given(:player)          { FactoryGirl.create(:player) }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:header)          { "h1" }
  given(:button)          { I18n.t("edit") }
  given(:unauthorized)    { I18n.t("errors.messages.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }

  scenario "the admin and membership roles can manage players" do
    ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      visit new_admin_player_path
      expect(page).to_not have_css(failure)
      visit edit_admin_player_path(player)
      expect(page).to_not have_css(failure)
      visit players_path
      expect(page).to_not have_css(failure)
      visit admin_player_path(player)
      expect(page).to have_css(header, text: player.name)
      expect(page).to have_link(button)
    end
  end

  scenario "other roles can only index players" do
    not_ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      visit new_admin_player_path
      expect(page).to have_css(failure, text: unauthorized)
      visit edit_admin_player_path(player)
      expect(page).to have_css(failure, text: unauthorized)
      visit players_path
      expect(page).to_not have_css(failure)
      visit admin_player_path(player)
      expect(page).to have_css(failure, text: unauthorized)
    end
  end

  scenario "guests can only index players" do
    logout
    visit new_admin_player_path
    expect(page).to have_css(failure, text: unauthorized)
    visit edit_admin_player_path(player)
    expect(page).to have_css(failure, text: unauthorized)
    visit players_path
    expect(page).to_not have_css(failure)
    visit admin_player_path(player)
    expect(page).to have_css(failure, text: unauthorized)
  end
end

feature "Create players" do
  before(:each) do
    login("membership")
  end

  given(:success)    { "div.alert-success" }
  given(:help)       { "div.help-block" }
  given(:first_name) { I18n.t("player.first_name") }
  given(:last_name)  { I18n.t("player.last_name") }
  given(:dob)        { I18n.t("player.dob") }
  given(:joined)     { I18n.t("player.joined") }
  given(:gender)     { I18n.t("player.gender.gender") }
  given(:male)       { I18n.t("player.gender.M") }
  given(:female)     { I18n.t("player.gender.F") }
  given(:federation) { I18n.t("player.federation") }
  given(:email)      { I18n.t("player.email") }
  given(:address)    { I18n.t("player.address") }
  given(:title)      { I18n.t("player.title.player") }
  given(:status)     { I18n.t("player.status.status") }
  given(:inactive)   { I18n.t("player.status.inactive") }
  given(:save)       { I18n.t("save") }

  scenario "sucessful creation with set join date" do
    click_link "New Player"
    fill_in first_name, with: "mark j l"
    fill_in last_name, with: "orr"
    fill_in dob, with: "1955/11/09"
    fill_in joined, with: "2013.10.20"
    fill_in email, with: "mark.j.l.orr@googlemail.com"
    fill_in address, with: "13/6 Rennie's Isle, Edinburgh"
    select male, from: gender
    select "Ireland", from: federation
    select "IM", from: title
    click_button save
    expect(page).to have_css(success, text: "created")
    player = Player.last
    expect(player.first_name).to eq "Mark J. L."
    expect(player.last_name).to eq "Orr"
    expect(player.dob.to_s).to eq "1955-11-09"
    expect(player.gender).to eq "M"
    expect(player.joined.to_s).to eq "2013-10-20"
    expect(player.fed).to eq "IRL"
    expect(player.email).to eq "mark.j.l.orr@googlemail.com"
    expect(player.address).to eq "13/6 Rennie's Isle, Edinburgh"
    expect(player.player_title).to eq "IM"
    expect(player.arbiter_title).to be_nil
    expect(player.trainer_title).to be_nil
    expect(player.source).to eq "officer"
    expect(player.status).to eq "active"
    expect(player.player_id).to be_nil
  end

  scenario "sucessful creation with default join date" do
    click_link "New Player"
    fill_in first_name, with: "Gearóidín"
    fill_in last_name, with: "Uí Laighléis"
    fill_in dob, with: "1964-06-10"
    select female, from: gender
    click_button save
    expect(page).to have_css(success, text: "created")
    player = Player.last
    expect(player.first_name).to eq "Gearoidin"
    expect(player.last_name).to eq "Ui Laighleis"
    expect(player.dob.to_s).to eq "1964-06-10"
    expect(player.gender).to eq "F"
    expect(player.joined.to_s).to eq Date.today.to_s
    expect(player.source).to eq "officer"
    expect(player.status).to eq "active"
    expect(player.player_id).to be_nil
  end
  
  scenario "join date and dob should be consistent" do
    click_link "New Player"
    fill_in first_name, with: "Penny"
    fill_in last_name, with: "Orr"
    fill_in dob, with: "1986-06-16"
    fill_in joined, with: "1985-10-20"
    select female, from: gender
    click_button save
    expect(page).to have_css(help, text: "after")
  end

  scenario "join date should not be in the future" do
    click_link "New Player"
    fill_in first_name, with: "Penny"
    fill_in last_name, with: "Orr"
    fill_in dob, with: "1986-06-16"
    fill_in joined, with: Date.today.days_since(1)
    select female, from: gender
    click_button save
    expect(page).to have_css(help, text: "future")
  end
  
  scenario "create a guest user" do
    click_link "New Player"
    fill_in first_name, with: "Guest"
    fill_in last_name, with: "User"
    select inactive, from: status
    click_button save
    expect(page).to have_css(success, text: "created")
    player = Player.last
    expect(player.first_name).to eq "Guest"
    expect(player.last_name).to eq "User"
    expect(player.dob).to be_nil
    expect(player.gender).to be_nil
    expect(player.joined.to_s).to eq Date.today.to_s
    expect(player.source).to eq "officer"
    expect(player.status).to eq "inactive"
    expect(player.player_id).to be_nil
  end
end

feature "Edit players" do
  before(:each) do
    login("membership")
  end

  given(:success)    { "div.alert-success" }
  given(:help)       { "div.help-block" }
  given(:player)     { FactoryGirl.create(:player) }
  given(:master)     { FactoryGirl.create(:player) }
  given(:duplicate)  { FactoryGirl.create(:player, player_id: master.id) }
  given(:first_name) { I18n.t("player.first_name") }
  given(:last_name)  { I18n.t("player.last_name") }
  given(:dob)        { I18n.t("player.dob") }
  given(:joined)     { I18n.t("player.joined") }
  given(:gender)     { I18n.t("player.gender.gender") }
  given(:male)       { I18n.t("player.gender.M") }
  given(:female)     { I18n.t("player.gender.F") }
  given(:club)       { I18n.t("club.club")}
  given(:none)       { I18n.t("none")}
  given(:master_id)  { I18n.t("player.master_id") }
  given(:status)     { I18n.t("player.status.status") }
  given(:inactive)   { I18n.t("player.status.inactive") }
  given(:deceased)   { I18n.t("player.status.deceased") }
  given(:save)       { I18n.t("save") }
  given(:edit)       { I18n.t("edit") }
  given(:please)     { I18n.t("please_select") }

  scenario "marking a player as deceased" do
    expect(player.status).to eq "active"
    visit admin_player_path(player)
    click_link edit
    select deceased, from: status
    click_button save
    expect(page).to have_css(success, text: "updated")
    expect(page).to have_css("h1 span", text: I18n.t("player.status.deceased"))
    expect(page).to have_xpath("//th[.='#{I18n.t("player.status.status")}']/following-sibling::td", text: I18n.t("player.status.deceased"))
    player.reload
    expect(player.status).to eq "deceased"
  end

  scenario "changing club" do
    expect(player.club_id).to be_nil
    FactoryGirl.create(:club, name: "Bangor")
    FactoryGirl.create(:club, name: "Hollywood")
    FactoryGirl.create(:club, name: "Carrickfergus")
    visit admin_player_path(player)

    click_link edit
    select "Hollywood", from: club
    click_button save
    expect(page).to have_css(success, text: "updated")
    expect(page).to have_xpath("//th[.='#{I18n.t("club.club")}']/following-sibling::td", text: "Hollywood")
    player.reload
    expect(player.club.name).to eq "Hollywood"

    click_link edit
    select none, from: club
    click_button save
    player.reload
    expect(player.club_id).to be_nil
  end

  scenario "marking a player as a duplicate" do
    expect(player.duplicate?).to be_false
    expect(player.status).to eq "active"
    visit edit_admin_player_path(player)
    fill_in master_id, with: master.id
    click_button save
    expect(page).to have_css(success, text: "updated")
    expect(page).to have_css("h1 span", text: I18n.t("player.duplicate"))
    expect(page).to have_xpath("//th[.='#{I18n.t("player.status.status")}']/following-sibling::td", text: I18n.t("player.status.inactive"))
    player.reload
    expect(player.duplicate?).to be_true
    expect(player.player_id).to eq master.id
    expect(player.status).to eq "inactive"
    click_link master.id
    expect(page).to have_css("h1", text: master.name)
  end

  scenario "can't be a duplicate of self, another duplicate or a non-existant record" do
    visit edit_admin_player_path(player)
    fill_in master_id, with: player.id
    click_button save
    expect(page).to have_css(help, text: "self")
    fill_in master_id, with: duplicate.id
    click_button save
    expect(page).to have_css(help, text: "duplicate a duplicate")
    fill_in master_id, with: 999
    click_button save
    expect(page).to have_css(help, text: "non-existent")
  end

  scenario "dob, joined and gender not required for inactive" do
    expect(player.status).to eq "active"
    visit edit_admin_player_path(player)
    fill_in dob, with: ""
    fill_in joined, with: ""
    select please, from: gender
    click_button save
    expect(page).to have_css(help, text: "can't be blank when status is active", count: 3)
    select inactive, from: status
    click_button save
    expect(page).to have_css(success, text: "updated")
    player.reload
    expect(player.dob).to be_nil
    expect(player.joined).to be_nil
    expect(player.gender).to be_nil
    expect(player.status).to eq "inactive"
  end
end
