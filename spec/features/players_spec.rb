require 'spec_helper'

feature "Search players" do
  before(:each) do
    @p = []
    @p << FactoryGirl.create(:player, first_name: "Mark", last_name: "Orr", dob: "1955-11-09")
    @p << FactoryGirl.create(:player, first_name: "Pat", last_name: "Reynolds", dob: "1955-08-15")
    @p << FactoryGirl.create(:player, first_name: "Patrick", last_name: "Bell", dob: "1950-08-08")
    @p << FactoryGirl.create(:player, first_name: "Mark", last_name: "Quinn", dob: "1976-08-08")
    @p << FactoryGirl.create(:player, first_name: "Ciaran", last_name: "Quinn", dob: "1960-10-07")
    @p << FactoryGirl.create(:player, first_name: "Ciaran", last_name: "Quinn", dob: "1960-10-07", player_id: @p.last.id)
    @p << FactoryGirl.create(:player, first_name: "Debbie", last_name: "Quinn", dob: "1969-11-20", gender: "F")
    @p << FactoryGirl.create(:player, first_name: "Patrick", last_name: "Yound", dob: "1965-01-24", status: "inactive")
    @p << FactoryGirl.create(:player, first_name: "Glen", last_name: "Adams", dob: "1975-03-04", status: "inactive")
    @p << FactoryGirl.create(:player, first_name: "Tom", last_name: "Clarke", dob: "1959-04-17", status: "deceased")
    @p << FactoryGirl.create(:player, first_name: "Arthur", last_name: "Cootes", dob: nil, status: "deceased")
    @p << FactoryGirl.create(:player, first_name: "Sam", last_name: "Lynne", dob: "1938-12-12", status: "deceased")
    @p << FactoryGirl.create(:player, first_name: "Kasper", last_name: "Agaard", dob: nil, status: "foreign")
    @p << FactoryGirl.create(:player, first_name: "Robert", last_name: "Zysk", dob: nil, status: "foreign")
    @p << FactoryGirl.create(:player, first_name: "Zulhasrifal", last_name: "Zulhasrifal", dob: nil, status: "foreign")
    @p << FactoryGirl.create(:player, first_name: "Jure", last_name: "Zorko", dob: nil, status: "foreign")
    visit players_path
  end

  given(:search)    { I18n.t("search") }
  given(:result)    { "//table[@id='results']/tbody/tr" }
  given(:link)      { "//table[@id='results']/tbody/tr/td/a[starts-with(@href,'/admin/players/')]" }
  given(:male)      { I18n.t("player.gender.M") }
  given(:female)    { I18n.t("player.gender.F") }
  given(:deceased)  { I18n.t("player.status.deceased") }
  given(:foreign)   { I18n.t("player.status.foreign") }
  given(:inactive)  { I18n.t("player.status.inactive") }
  given(:duplicate) { I18n.t("player.duplicate") }

  scenario "default" do
    click_button search
    expect(page).to have_xpath(result, count: 6)
    login("membership")
    visit players_path
    expect(page).to have_xpath(link, count: 7) # one extra for the membership officer's player
  end

  scenario "id" do
    fill_in "id", with: @p[0].id
    click_button search
    expect(page).to have_xpath(result, count: 1)
    fill_in "id", with: 99
    click_button search
    expect(page).to_not have_xpath(result)
  end

  scenario "last name" do
    fill_in "last_name", with: "QUINN"
    click_button search
    expect(page).to have_xpath(result, count: 3)
  end

  scenario "first name" do
    fill_in "first_name", with: "mark"
    click_button search
    expect(page).to have_xpath(result, count: 2)
    fill_in "first_name", with: "padraig"
    click_button search
    expect(page).to have_xpath(result, count: 2) # matches Pat and Patrick via icu_name
  end

  scenario "gender" do
    select male, from: "gender"
    click_button search
    expect(page).to have_xpath(result, count: 5)
    select female, from: "gender"
    click_button search
    expect(page).to have_xpath(result, count: 1)
  end

  scenario "yob" do
    fill_in "yob", with: "1955"
    click_button search
    expect(page).to have_xpath(result, count: 2)
    fill_in "yob", with: "1966"
    click_button search
    expect(page).to_not have_xpath(result)
    select ">", from: "relation"
    click_button search
    expect(page).to have_xpath(result, count: 2)
    select "<", from: "relation"
    click_button search
    expect(page).to have_xpath(result, count: 4)
  end
  
  scenario "status" do
    expect(page).to_not have_select("status")
    login("membership")
    visit players_path
    select duplicate, from: "status"
    click_button search
    expect(page).to have_xpath(result, count: 1)
    select inactive, from: "status"
    click_button search
    expect(page).to have_xpath(result, count: 2)
    select deceased, from: "status"
    click_button search
    expect(page).to have_xpath(result, count: 3)
    select foreign, from: "status"
    click_button search
    expect(page).to have_xpath(result, count: 4)
  end
end
