# encoding: utf-8
require 'spec_helper'

feature "Authorization for clubs" do
  given(:ok_roles)        { %w[admin editor] }
  given(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) } }
  given(:club)            { FactoryGirl.create(:club) }
  given(:paths)           { [admin_clubs_path, admin_club_path(club), edit_admin_club_path(club)] }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:unauthorized)    { I18n.t("errors.messages.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }

  scenario "the admin and editor roles can manage clubs" do
    ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      paths.each do |path|
        visit path
        expect(page).not_to have_css(failure)
      end
    end
  end

  scenario "other roles cannot access clubs" do
    not_ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      paths.each do |path|
        visit path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end

  scenario "guests cannot access users" do
    logout
    paths.each do |path|
      visit path
      expect(page).to have_css(failure, text: unauthorized)
    end
  end
end

feature "Searching clubs" do
  before(:each) do
    FactoryGirl.create(:club, name: "Bangor", city: "Groomsport", contact: "Mark", province: "ulster", county: "down")
    FactoryGirl.create(:club, name: "Bray/Greystones", city: "Dublin", contact: "Mervyn", province: "leinster", county: "dublin")
    FactoryGirl.create(:club, name: "Aer Lingus", city: "Dublin", contact: "Gearóidín", province: "leinster", county: "dublin")
    FactoryGirl.create(:club, name: "Cortex", city: "Arklow", contact: "Danny", province: "leinster", county: "wicklow", active: false)
    login("editor")
    visit admin_clubs_path
    @xpath = "//table[@id='results']/tbody/tr"
  end
  
  it "shows all active records by default" do
    expect(page).to have_xpath(@xpath, count: 3)
  end

  it "finds records by name" do
    fill_in "Name", with: "Lingus"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_xpath(@xpath, text: "Aer Lingus")
    fill_in "Name", with: "b"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 2)
    expect(page).to have_xpath(@xpath, text: "Bangor")
    expect(page).to have_xpath(@xpath, text: "Bray/Greystones")
    fill_in "Name", with: "/"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_xpath(@xpath, text: "Bray/Greystones")
  end

  it "finds records by city" do
    fill_in "City", with: "Dub"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 2)
    expect(page).to have_xpath(@xpath, text: "Bray/Greystones")
    expect(page).to have_xpath(@xpath, text: "Aer Lingus")
  end

  it "finds records by contact" do
    fill_in "Contact", with: "óidí"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_xpath(@xpath, text: "Gearóidín")
    fill_in "Contact", with: "Dan"
    select "Either", from: "Active"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_xpath(@xpath, text: "Danny")
  end

  it "finds records by activity" do
    select "Either", from: "Active"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 4)
    select "Active", from: "Active"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 3)
    select "Inactive", from: "Active"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_xpath(@xpath, text: "Cortex")
  end

  it "returns no results when appropriate" do
    fill_in "Contact", with: "Dan"
    fill_in "Name", with: "Aer"
    click_button "Search"
    expect(page).to_not have_xpath(@xpath)
    expect(page).to have_css("div.alert-warning", text: "No matches")
  end

  it "remembers last search" do
    fill_in "Contact", with: "Gear"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    click_link "Aer Lingus"
    click_link I18n.t("last_search")
    expect(page).to have_xpath(@xpath, count: 1)
  end
end

feature "Showing a club" do
  before(:each) do
    login("editor")
  end
  
  def xpath(label)
    "//table//th[.='#{label}']/following-sibling::td"
  end
  
  it "all fields" do
    params = {
      active:    true,
      address:   "McKee Clock",
      city:      "Bangor",
      contact:   "Mark Orr",
      county:    "down",
      district:  "Marina",
      email:     "mark@bangor.net",
      latitude:  54.65654,
      longitude: -5.67529,
      meetings:  "7pm Tuesdays and Thursdays",
      name:      "Bangor",
      phone:     "07968 537010",
      province:  "ulster",
      web:       "http://chess.bangor.net",
    }
    bangor = FactoryGirl.create(:club, params)
    visit admin_club_path(bangor)
    params.each do |param, value|
      if param == :active
        expect(page).to have_xpath(xpath(I18n.t("club.#{param}")), text: I18n.t("yes"))
      else
        expect(page).to have_xpath(xpath(I18n.t("club.#{param}")), text: value)
      end
    end
  end
end
