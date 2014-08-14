require 'rails_helper'

describe Player do
  include_context "features"

  let(:club)            { I18n.t("club.club") }
  let(:deceased)        { I18n.t("player.status.deceased") }
  let(:dob)             { I18n.t("player.dob") }
  let(:federation)      { I18n.t("player.federation") }
  let(:female)          { I18n.t("player.gender.F") }
  let(:first_name)      { I18n.t("player.first_name") }
  let(:gender)          { I18n.t("player.gender.gender") }
  let(:home)            { I18n.t("player.phone.home") }
  let(:inactive_status) { I18n.t("player.status.inactive") }
  let(:joined)          { I18n.t("player.joined") }
  let(:last_name)       { I18n.t("player.last_name") }
  let(:male)            { I18n.t("player.gender.M") }
  let(:master_id)       { I18n.t("player.master_id") }
  let(:mobile)          { I18n.t("player.phone.mobile") }
  let(:none)            { I18n.t("player.no_club") }
  let(:privacy)         { I18n.t("player.privacy") }
  let(:status)          { I18n.t("player.status.status") }
  let(:title)           { I18n.t("player.title.player") }
  let(:work)            { I18n.t("player.phone.work") }

  context "authorization" do
    let(:header) { "h1" }
    let(:level1) { %w[admin membership] }
    let(:level2) { %w[inspector] }
    let(:level3) { User::ROLES.reject { |role| level1.include?(role) || level2.include?(role) }.append("guest") }
    let(:player) { create(:player) }

    it "level 1 can manage" do
      level1.each do |role|
        login role
        visit new_admin_player_path
        expect(page).to_not have_css(failure)
        visit edit_admin_player_path(player)
        expect(page).to_not have_css(failure)
        visit players_path
        expect(page).to_not have_css(failure)
        visit admin_player_path(player)
        expect(page).to have_css(header, text: player.name)
        expect(page).to have_link(edit)
      end
    end

    it "level 2 can index and show" do
      level2.each do |role|
        login role
        visit new_admin_player_path
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_player_path(player)
        expect(page).to have_css(failure, text: unauthorized)
        visit players_path
        expect(page).to_not have_css(failure)
        visit admin_player_path(player)
        expect(page).to_not have_css(failure, text: unauthorized)
        expect(page).to have_css(header, text: player.name)
        expect(page).to_not have_link(edit)
      end
    end

    it "level 3 can only index" do
      level3.each do |role|
        login role
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

  context "create" do
    before(:each) do
      login "membership"
      visit players_path
      click_link new_one
    end

    it "sucessful creation with set join date" do
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

      expect(page).to have_css(success, text: created)
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
      fill_in first_name, with: "Gearóidín"
      fill_in last_name, with: "Uí Laighléis"
      fill_in dob, with: "1964-06-10"
      select female, from: gender
      click_button save

      expect(page).to have_css(success, text: created)
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
      fill_in first_name, with: "Penny"
      fill_in last_name, with: "Orr"
      fill_in dob, with: "1986-06-16"
      fill_in joined, with: "1985-10-20"
      select female, from: gender
      click_button save

      expect(page).to have_css(field_error, text: "after")
    end

    it "join date should not be in the future" do
      fill_in first_name, with: "Penny"
      fill_in last_name, with: "Orr"
      fill_in dob, with: "1986-06-16"
      fill_in joined, with: Date.today.days_since(1)
      select female, from: gender
      click_button save

      expect(page).to have_css(field_error, text: "before")
    end

    it "email must be valid if present" do
      fill_in first_name, with: "Pete"
      fill_in last_name, with: "Morriss"
      fill_in dob, with: "1947-07-11"
      select male, from: gender
      fill_in email, with: "pete.morriss.nuigalway.ie"
      click_button save

      expect(page).to have_css(field_error, text: "invalid")
    end

    it "create a guest user" do
      fill_in first_name, with: "Guest"
      fill_in last_name, with: "User"
      select inactive_status, from: status
      click_button save

      expect(page).to have_css(success, text: created)
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

  context "edit" do
    let(:player)     { create(:player) }
    let(:master)     { create(:player) }
    let(:duplicate)  { create(:player, player_id: master.id) }

    before(:each) do
      login("membership")
    end

    it "marking a player as deceased" do
      expect(player.status).to eq "active"
      visit admin_player_path(player)
      click_link edit
      select deceased, from: status
      click_button save

      expect(page).to have_css(success, text: updated)
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

      expect(page).to have_css(success, text: updated)
      expect(page).to have_xpath("//th[.='#{I18n.t("club.club")}']/following-sibling::td", text: "Hollywood")
      player.reload
      expect(player.club.name).to eq "Hollywood"

      click_link edit
      select none, from: club
      click_button save
      expect(page).to have_css(success, text: updated)
      player.reload
      expect(player.club_id).to be_nil
    end

    it "marking a player as a duplicate" do
      expect(player.duplicate?).to be false
      expect(player.status).to eq "active"
      visit edit_admin_player_path(player)
      fill_in master_id, with: master.id
      click_button save

      expect(page).to have_css(success, text: updated)
      expect(page).to have_css("h1 span", text: I18n.t("player.duplicate"))
      expect(page).to have_xpath("//th[.='#{I18n.t("player.status.status")}']/following-sibling::td", text: inactive_status)
      player.reload

      expect(player.duplicate?).to be true
      expect(player.player_id).to eq master.id
      expect(player.status).to eq "inactive"
      click_link master.id
      expect(page).to have_css("h1", text: master.name)
    end

    it "can't be a duplicate of self, another duplicate or a non-existant record" do
      visit edit_admin_player_path(player)
      fill_in master_id, with: player.id
      click_button save
      expect(page).to have_css(field_error, text: "self")
      fill_in master_id, with: duplicate.id
      click_button save
      expect(page).to have_css(field_error, text: "duplicate a duplicate")
      fill_in master_id, with: 999
      click_button save
      expect(page).to have_css(field_error, text: "non-existent")
    end

    it "dob, joined and gender not required for inactive" do
      expect(player.status).to eq "active"
      visit edit_admin_player_path(player)
      fill_in dob, with: ""
      fill_in joined, with: ""
      select please, from: gender
      click_button save
      expect(page).to have_css(field_error, text: "can't be blank when status is active", count: 3)
      select inactive_status, from: status
      click_button save

      expect(page).to have_css(success, text: updated)
      player.reload

      expect(player.dob).to be_nil
      expect(player.joined).to be_nil
      expect(player.gender).to be_nil
      expect(player.status).to eq "inactive"
    end

    it "privacy" do
      expect(player.privacy).to be_nil
      visit edit_admin_player_path(player)
      select home, from: privacy
      select work, from: privacy
      click_button save
      expect(page).to have_css(success, text: updated)
      player.reload

      expect(page).to have_content(player.formatted_privacy)
      expect(player.privacy).to eq "home_phone work_phone"
    end
  end

  context "previous and next links" do
    11.times do |i|
      let!("player#{i+1}".to_sym) { create(:player, id: i + 1) }
    end
    let!(:user1) { create(:user, roles: "admin", player: player1) }
    let!(:user2) { create(:user, player: player2) }

    before(:each) do
      login user1
    end

    let(:header)    { "h1" }
    let(:prev_link) { "☜" }
    let(:next_link) { "☞" }

    it "first few" do
      visit players_path
      click_link player1.name(reversed: true)

      expect(page).to have_css(header, text: player1.name)
      click_link next_link

      expect(page).to have_css(header, text: player2.name)
      click_link next_link

      expect(page).to have_css(header, text: player3.name)
      expect(page).to have_link(next_link)
      click_link prev_link

      expect(page).to have_css(header, text: player2.name)
      click_link prev_link

      expect(page).to have_css(header, text: player1.name)
      expect(page).to_not have_link(prev_link)
    end

    it "last few" do
      visit players_path
      click_link player9.name(reversed: true)

      expect(page).to have_css(header, text: player9.name)
      click_link next_link

      expect(page).to have_css(header, text: player10.name)
      click_link next_link

      expect(page).to have_button(search)
      click_link player11.name(reversed: true)

      expect(page).to have_css(header, text: player11.name)
      expect(page).to_not have_link(next_link)
      click_link prev_link

      expect(page).to have_button(search)
      click_link player10.name(reversed: true)

      expect(page).to have_css(header, text: player10.name)
      click_link prev_link

      expect(page).to have_css(header, text: player9.name)
      expect(page).to have_link(prev_link)
    end

    it "only enough for one page" do
      player11.destroy
      visit players_path

      visit admin_player_path(player1)
      expect(page).to have_css(header, text: player1.name)
      expect(page).to_not have_link(prev_link)
      expect(page).to have_link(next_link)

      visit admin_player_path(player10)
      expect(page).to have_css(header, text: player10.name)
      expect(page).to have_link(prev_link)
      expect(page).to_not have_link(next_link)
    end

    it "one is destroyed after the search is saved" do
      visit players_path

      visit admin_player_path(player2)
      expect(page).to have_css(header, text: player2.name)
      expect(page).to have_link(prev_link)
      expect(page).to have_link(next_link)

      visit admin_player_path(player4)
      expect(page).to have_css(header, text: player4.name)
      expect(page).to have_link(prev_link)
      expect(page).to have_link(next_link)

      player3.destroy

      visit admin_player_path(player2)
      expect(page).to have_css(header, text: player2.name)
      expect(page).to have_link(prev_link)
      expect(page).to_not have_link(next_link)

      visit admin_player_path(player4)
      expect(page).to have_css(header, text: player4.name)
      expect(page).to_not have_link(prev_link)
      expect(page).to have_link(next_link)
    end

    it "none without a search" do
      visit admin_player_path(player7)

      expect(page).to_not have_link(prev_link)
      expect(page).to_not have_link(next_link)
    end

    it "none for ordinary user" do
      login user2

      visit players_path
      click_link player2.name(reversed: true)

      expect(page).to have_css(header, text: player2.name)
      expect(page).to_not have_link(prev_link)
      expect(page).to_not have_link(next_link)
    end
  end
end
