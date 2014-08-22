require 'rails_helper'

describe Player do
  include_context "features"

  let(:club)            { I18n.t("club.club") }
  let(:deceased)        { I18n.t("player.status.deceased") }
  let(:duplicate)       { I18n.t("player.duplicate") }
  let(:edit_profile)    { I18n.t("player.edit_profile") }
  let(:fed)             { I18n.t("player.federation") }
  let(:female)          { I18n.t("player.gender.F") }
  let(:gender)          { I18n.t("player.gender.gender") }
  let(:last_name)       { I18n.t("player.last_name") }
  let(:first_name)      { I18n.t("player.first_name") }
  let(:foreign)         { I18n.t("player.status.foreign") }
  let(:home)            { I18n.t("player.phone.home") }
  let(:id)              { I18n.t("player.id") }
  let(:inactive_status) { I18n.t("player.status.inactive") }
  let(:male)            { I18n.t("player.gender.M") }
  let(:none)            { I18n.t("player.no_club") }
  let(:privacy)         { I18n.t("player.privacy") }
  let(:profile)         { I18n.t("player.profile") }
  let(:status)          { I18n.t("player.status.status") }
  let(:t_arbiter)       { I18n.t("player.title.arbiter") }
  let(:t_trainer)       { I18n.t("player.title.trainer") }
  let(:t_player)        { I18n.t("player.title.player") }
  let(:title)           { I18n.t("player.title.title") }
  let(:yob)             { I18n.t("player.abbrev.yob") }
  let(:work)            { I18n.t("player.phone.work") }

  context "authorization" do
    let(:header)  { "h1" }
    let(:level1)  { %w[admin membership] }
    let(:level2)  { %w[inspector] }
    let(:level3)  { [ user ] }
    let(:level4)  { User::ROLES.reject { |role| level1.include?(role) || level2.include?(role) }.append("guest") }
    let!(:player) { create(:player) }
    let!(:user)   { create(:user) }

    it "level 1 can show and edit both" do
      level1.each do |role|
        login role
        [player, user.player].each do |p|
          visit players_path
          click_link p.name(reversed: true)
          expect(page).to have_css(header, text: p.name)
          click_link edit_profile
          click_link cancel
        end
      end
    end

    it "level 2 can show both but not edit either" do
      level2.each do |role|
        login role
        [player, user.player].each do |p|
          visit players_path
          click_link p.name(reversed: true)
          expect(page).to have_css(header, text: p.name)
          expect(page).to_not have_link(edit_profile)
          visit edit_player_path(p)
          expect(page).to have_css(failure, text: unauthorized)
        end
      end
    end

    it "level 3 can show and edit only their own player" do
      level3.each do |role|
        login role
        visit players_path
        click_link user.player.name(reversed: true)
        expect(page).to have_css(header, text: user.player.name)
        click_link edit_profile
        click_link cancel
        visit players_path
        expect(page).to_not have_link(player.name)
        visit admin_player_path(player)
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_player_path(player)
        expect(page).to have_css(failure, text: unauthorized)
      end
    end

    it "level 4 can neither show nor edit either player" do
      level4.each do |role|
        login role
        [player, user.player].each do |p|
          visit players_path
          expect(page).to_not have_link(p.name)
          visit admin_player_path(p)
          expect(page).to have_css(failure, text: unauthorized)
          visit edit_player_path(p)
          expect(page).to have_css(failure, text: unauthorized)
        end
      end
    end
  end

  context "edit" do
    let(:player) { create(:player) }
    let(:user)   { create(:user, player: player) }
    let(:data)   { attributes_for(:player) }

    before(:each) do
      login(user)
    end

    it "club" do
      expect(player.club_id).to be_nil
      create(:club, name: "Bangor")
      create(:club, name: "Hollywood")
      create(:club, name: "Carrickfergus")

      click_link profile
      click_link edit_profile
      select "Hollywood", from: club
      click_button save

      expect(page).to have_css(success, text: updated)
      player.reload
      expect(player.club.name).to eq "Hollywood"

      click_link edit_profile
      select none, from: club
      click_button save
      expect(page).to have_css(success, text: updated)
      player.reload
      expect(player.club).to be_nil
      
      expect(JournalEntry.players.where(action: "update", column: :club_id, by: user.signature, journalable_id: player.id).count).to eq 2
    end

    it "email" do
      click_link profile
      click_link edit_profile
      fill_in email, with: "rubbish"
      click_button save

      expect(page).to have_css(field_error, text: "invalid")

      fill_in email, with: data[:email]
      click_button save
      expect(page).to have_css(success, text: updated)
      player.reload

      expect(player.email).to eq data[:email]
      
      expect(JournalEntry.players.where(action: "update", column: :email, by: user.signature, journalable_id: player.id).count).to eq 1
    end

    it "privacy" do
      expect(player.privacy).to be_nil

      click_link profile
      click_link edit_profile
      select home, from: privacy
      select work, from: privacy
      click_button save
      player.reload

      expect(page).to have_css(success, text: updated)
      expect(page).to have_content(player.formatted_privacy)
      expect(player.privacy).to eq "home_phone work_phone"
      
      expect(JournalEntry.players.where(action: "update", column: :privacy, by: user.signature, journalable_id: player.id).count).to eq 1
    end
  end

  context "search" do
    let(:result) { "//table[@id='results']/tbody/tr" }
    let(:link)   { "//table[@id='results']/tbody/tr/td/a[starts-with(@href,'/admin/players/')]" }

    before(:each) do
      @p = []
      @p << create(:player, first_name: "Mark", last_name: "Orr", dob: "1955-11-09", player_title: "IM", trainer_title: "FST")
      @p << create(:player, first_name: "Pat", last_name: "Reynolds", dob: "1955-08-15", arbiter_title: "IA")
      @p << create(:player, first_name: "Patrick", last_name: "Bell", dob: "1950-08-08", fed: nil, arbiter_title: "FA")
      @p << create(:player, first_name: "Mark", last_name: "Quinn", dob: "1976-08-08", player_title: "IM")
      @p << create(:player, first_name: "Ciaran", last_name: "Quinn", dob: "1960-10-07")
      @p << create(:player, first_name: "Ciaran", last_name: "Quinn", dob: "1960-10-07", player_id: @p.last.id)
      @p << create(:player, first_name: "Debbie", last_name: "Quinn", dob: "1969-11-20", gender: "F", player_title: "WCM")
      @p << create(:player, first_name: "Patrick", last_name: "Yound", dob: "1965-01-24", status: "inactive")
      @p << create(:player, first_name: "Glen", last_name: "Adams", dob: "1975-03-04", status: "inactive")
      @p << create(:player, first_name: "Tom", last_name: "Clarke", dob: "1959-04-17", status: "deceased")
      @p << create(:player, first_name: "Arthur", last_name: "Cootes", dob: nil, status: "deceased")
      @p << create(:player, first_name: "Sam", last_name: "Lynne", dob: "1938-12-12", status: "deceased")
      @p << create(:player, first_name: "Kasper", last_name: "Agaard", dob: nil, status: "foreign")
      @p << create(:player, first_name: "Robert", last_name: "Zysk", dob: nil, status: "foreign")
      @p << create(:player, first_name: "Magomed", last_name: "Zulfugarli", dob: nil, status: "foreign", fed: "AZE")
      @p << create(:player, first_name: "Jure", last_name: "Zorko", dob: nil, status: "foreign")
      visit players_path
    end

    it "default" do
      click_button search
      expect(page).to have_xpath(result, count: 6)
      login "membership"
      visit players_path
      expect(page).to have_xpath(link, count: 7) # one extra for the new membership officer's player
    end

    it "ID" do
      fill_in id, with: @p[0].id
      click_button search
      expect(page).to have_xpath(result, count: 1)
      fill_in id, with: 99
      click_button search
      expect(page).to_not have_xpath(result)
    end

    it "last name" do
      fill_in last_name, with: "QUINN"
      click_button search
      expect(page).to have_xpath(result, count: 3)
    end

    it "first name" do
      fill_in first_name, with: "mark"
      click_button search
      expect(page).to have_xpath(result, count: 2)
      fill_in first_name, with: "padraig"
      click_button search
      expect(page).to have_xpath(result, count: 2) # matches Pat and Patrick via icu_name
    end

    it "gender" do
      select male, from: gender
      click_button search
      expect(page).to have_xpath(result, count: 5)
      select female, from: gender
      click_button search
      expect(page).to have_xpath(result, count: 1)
    end

    it "yob" do
      fill_in yob, with: "1955"
      click_button search
      expect(page).to have_xpath(result, count: 2)
      fill_in yob, with: "1966"
      click_button search
      expect(page).to_not have_xpath(result)
      select ">", from: "yob_relation"
      click_button search
      expect(page).to have_xpath(result, count: 2)
      select "<", from: "yob_relation"
      click_button search
      expect(page).to have_xpath(result, count: 4)
    end

    it "federation" do
      select "Ireland", from: fed
      click_button search
      expect(page).to have_xpath(result, count: 5)
    end

    it "titles" do
      select "IM", from: title
      click_button search
      expect(page).to have_xpath(result, count: 2)
      select t_player, from: title
      click_button search
      expect(page).to have_xpath(result, count: 3)
      select "IA", from: title
      click_button search
      expect(page).to have_xpath(result, count: 1)
      select t_arbiter, from: title
      click_button search
      expect(page).to have_xpath(result, count: 2)
      select "FST", from: title
      click_button search
      expect(page).to have_xpath(result, count: 1)
      select t_trainer, from: title
      click_button search
      expect(page).to have_xpath(result, count: 1)
    end

    it "status" do
      expect(page).to_not have_select(status)
      login "membership"
      visit players_path
      select duplicate, from: status
      click_button search
      expect(page).to have_xpath(result, count: 1)
      select inactive_status, from: status
      click_button search
      expect(page).to have_xpath(result, count: 2)
      select deceased, from: status
      click_button search
      expect(page).to have_xpath(result, count: 3)
      select foreign, from: status
      click_button search
      expect(page).to have_xpath(result, count: 4)
      select "Azerbaijan", from: fed
      click_button search
      expect(page).to have_xpath(result, count: 1)
    end
  end
end
