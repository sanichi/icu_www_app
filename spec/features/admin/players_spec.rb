require 'spec_helper'

describe "Authorization for players" do
  let(:ok_roles)        { %w[admin membership] }
  let(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) } }
  let(:player)          { create(:player) }
  let(:success)         { "div.alert-success" }
  let(:failure)         { "div.alert-danger" }
  let(:header)          { "h1" }
  let(:button)          { I18n.t("edit") }
  let(:unauthorized)    { I18n.t("errors.alerts.unauthorized") }
  let(:signed_in_as)    { I18n.t("session.signed_in_as") }

  it "some roles can manage players" do
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

  it "other roles and guests can only index players" do
    not_ok_roles.push("guest").each do |role|
      if role == "guest"
        logout
      else
        login role
        expect(page).to have_css(success, text: signed_in_as)
      end
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
end

describe "Create players" do
  before(:each) do
    login("membership")
  end

  let(:success)    { "div.alert-success" }
  let(:help)       { "div.help-block" }
  let(:first_name) { I18n.t("player.first_name") }
  let(:last_name)  { I18n.t("player.last_name") }
  let(:dob)        { I18n.t("player.dob") }
  let(:joined)     { I18n.t("player.joined") }
  let(:gender)     { I18n.t("player.gender.gender") }
  let(:male)       { I18n.t("player.gender.M") }
  let(:female)     { I18n.t("player.gender.F") }
  let(:federation) { I18n.t("player.federation") }
  let(:email)      { I18n.t("email") }
  let(:address)    { I18n.t("address") }
  let(:home)       { I18n.t("player.phone.home") }
  let(:mobile)     { I18n.t("player.phone.mobile") }
  let(:work)       { I18n.t("player.phone.work") }
  let(:title)      { I18n.t("player.title.player") }
  let(:status)     { I18n.t("player.status.status") }
  let(:inactive)   { I18n.t("player.status.inactive") }
  let(:notes)      { I18n.t("notes") }
  let(:save)       { I18n.t("save") }

  it "sucessful creation with set join date" do
    click_link "New Player"
    fill_in first_name, with: "mark j l"
    fill_in last_name, with: "orr"
    fill_in dob, with: "1955/11/09"
    fill_in joined, with: "2013.10.20"
    fill_in email, with: "mark.j.l.orr@googlemail.com"
    fill_in address, with: "13/6 Rennie's Isle, Edinburgh"
    fill_in home, with: "+44 131 55 39 051"
    fill_in mobile, with: "+44 7968 537 010"
    fill_in work, with: "+44 0131 653 1250"
    select male, from: gender
    select "Ireland", from: federation
    select "IM", from: title
    fill_in notes, with: "ICU web developer and system manager."
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
    expect(player.home_phone).to eq "0044 131 5539051"
    expect(player.mobile_phone).to eq "0044 7968 537010"
    expect(player.work_phone).to eq "0044 131 6531250"
    expect(player.player_title).to eq "IM"
    expect(player.arbiter_title).to be_nil
    expect(player.trainer_title).to be_nil
    expect(player.source).to eq "officer"
    expect(player.status).to eq "active"
    expect(player.note).to eq "ICU web developer and system manager."
    expect(player.player_id).to be_nil
  end

  it "sucessful creation with default join date" do
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

  it "join date and dob should be consistent" do
    click_link "New Player"
    fill_in first_name, with: "Penny"
    fill_in last_name, with: "Orr"
    fill_in dob, with: "1986-06-16"
    fill_in joined, with: "1985-10-20"
    select female, from: gender
    click_button save
    expect(page).to have_css(help, text: "after")
  end

  it "join date should not be in the future" do
    click_link "New Player"
    fill_in first_name, with: "Penny"
    fill_in last_name, with: "Orr"
    fill_in dob, with: "1986-06-16"
    fill_in joined, with: Date.today.days_since(1)
    select female, from: gender
    click_button save
    expect(page).to have_css(help, text: "before")
  end

  it "create a guest user" do
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

describe "Edit players" do
  before(:each) do
    login("membership")
  end

  let(:success)    { "div.alert-success" }
  let(:help)       { "div.help-block" }
  let(:player)     { create(:player) }
  let(:master)     { create(:player) }
  let(:duplicate)  { create(:player, player_id: master.id) }
  let(:first_name) { I18n.t("player.first_name") }
  let(:last_name)  { I18n.t("player.last_name") }
  let(:dob)        { I18n.t("player.dob") }
  let(:joined)     { I18n.t("player.joined") }
  let(:gender)     { I18n.t("player.gender.gender") }
  let(:male)       { I18n.t("player.gender.M") }
  let(:female)     { I18n.t("player.gender.F") }
  let(:club)       { I18n.t("club.club")}
  let(:none)       { I18n.t("player.no_club")}
  let(:master_id)  { I18n.t("player.master_id") }
  let(:status)     { I18n.t("player.status.status") }
  let(:inactive)   { I18n.t("player.status.inactive") }
  let(:deceased)   { I18n.t("player.status.deceased") }
  let(:save)       { I18n.t("save") }
  let(:edit)       { I18n.t("edit") }
  let(:please)     { I18n.t("please_select") }

  it "marking a player as deceased" do
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

  it "changing club" do
    expect(player.club_id).to be_nil
    create(:club, name: "Bangor")
    create(:club, name: "Hollywood")
    create(:club, name: "Carrickfergus")
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

  it "marking a player as a duplicate" do
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

  it "can't be a duplicate of self, another duplicate or a non-existant record" do
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

  it "dob, joined and gender not required for inactive" do
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
