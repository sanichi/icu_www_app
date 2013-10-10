# encoding: utf-8
require 'spec_helper'

feature "Searching clubs" do
  before(:each) do
    FactoryGirl.create(:club, name: "Bangor", city: "Groomsport", contact: "Mark", province: "ulster", county: "down")
    FactoryGirl.create(:club, name: "Bray/Greystones", city: "Dublin", contact: "Mervyn", province: "leinster", county: "dublin")
    FactoryGirl.create(:club, name: "Aer Lingus", city: "Dublin", contact: "Gearóidín", province: "leinster", county: "dublin")
    FactoryGirl.create(:club, name: "Cortex", city: "Arklow", contact: "Danny", province: "leinster", county: "wicklow", active: false)
    visit clubs_path
    @xpath = "//table[@id='results']/tbody/tr"
  end
  
  it "shows all active records by default" do
    expect(page).to have_xpath(@xpath, count: 3)
  end

  it "find records by name" do
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

  it "find records by city" do
    fill_in "City", with: "Dub"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 2)
    expect(page).to have_xpath(@xpath, text: "Bray/Greystones")
    expect(page).to have_xpath(@xpath, text: "Aer Lingus")
  end

  it "find records by contact" do
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

  it "find records by activity" do
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

  it "return no results when appropriate" do
    fill_in "Contact", with: "Dan"
    fill_in "Name", with: "Aer"
    click_button "Search"
    expect(page).to_not have_xpath(@xpath)
    expect(page).to have_css("div.alert-warning", text: "No matches")
  end

  it "remember last search" do
    fill_in "Contact", with: "Gear"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    click_link "Aer Lingus"
    click_link I18n.t("last_search")
    expect(page).to have_xpath(@xpath, count: 1)
  end
end

feature "Showing a club" do  
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
      case param
      when :active
        expect(page).to have_xpath(xpath(I18n.t("club.#{param}")), text: I18n.t(value ? "yes" : "no"))
      when :county
        expect(page).to have_xpath(xpath(I18n.t("club.#{param}")), text: I18n.t("ireland.co.#{value}"))
      when :name
        expect(page).to have_css("h1", text: value)
      when :province
        expect(page).to have_xpath(xpath(I18n.t("club.#{param}")), text: I18n.t("ireland.prov.#{value}"))
      else
        expect(page).to have_xpath(xpath(I18n.t("club.#{param}")), text: value)
      end
    end
  end
end
