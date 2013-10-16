# encoding: utf-8
require 'spec_helper'

feature "Searching clubs" do
  before(:each) do
    FactoryGirl.create(:club, name: "Bangor", city: "Groomsport", contact: "Mark", county: "down")
    FactoryGirl.create(:club, name: "Bray/Greystones", city: "Dublin", contact: "Mervyn", county: "dublin")
    FactoryGirl.create(:club, name: "Aer Lingus", city: "Dublin", contact: "Gearóidín", county: "dublin")
    FactoryGirl.create(:club, name: "Cortex", city: "Arklow", contact: "Danny", county: "wicklow", active: false)
    visit clubs_path
    @xpath = "//div[starts-with(@id,'club_')]"
    @search = "Search"
  end
  
  it "shows all active records by default" do
    expect(page).to have_xpath(@xpath, count: 3)
  end

  it "find records by name" do
    label = I18n.t("club.name")
    fill_in label, with: "Lingus"
    click_button @search
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_xpath(@xpath, text: "Aer Lingus")
    fill_in label, with: "b"
    click_button @search
    expect(page).to have_xpath(@xpath, count: 2)
    expect(page).to have_xpath(@xpath, text: "Bangor")
    expect(page).to have_xpath(@xpath, text: "Bray/Greystones")
    fill_in label, with: "/"
    click_button @search
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_xpath(@xpath, text: "Bray/Greystones")
  end

  it "find records by city" do
    label = I18n.t("club.city")
    fill_in label, with: "Dub"
    click_button @search
    expect(page).to have_xpath(@xpath, count: 2)
    expect(page).to have_xpath(@xpath, text: "Bray/Greystones")
    expect(page).to have_xpath(@xpath, text: "Aer Lingus")
  end

  it "find records by county" do
    label = I18n.t("club.county")
    select "Dublin", from: label
    click_button @search
    expect(page).to have_xpath(@xpath, count: 2)
    expect(page).to have_xpath(@xpath, text: "Bray/Greystones")
    expect(page).to have_xpath(@xpath, text: "Aer Lingus")
    select "Down", from: label
    click_button @search
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_xpath(@xpath, text: "Bangor")
  end

  it "find records by province" do
    label = I18n.t("club.province")
    select "Lein", from: label
    click_button @search
    expect(page).to have_xpath(@xpath, count: 2)
    expect(page).to have_xpath(@xpath, text: "Bray/Greystones")
    expect(page).to have_xpath(@xpath, text: "Aer Lingus")
    select "Ulster", from: label
    click_button @search
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_xpath(@xpath, text: "Bangor")
  end

  it "find records by whether active or not" do
    label = I18n.t("club.active")
    select I18n.t("either"), from: label
    click_button @search
    expect(page).to have_xpath(@xpath, count: 4)
    select I18n.t("club.active"), from: label
    click_button @search
    expect(page).to have_xpath(@xpath, count: 3)
    select I18n.t("club.inactive"), from: label
    click_button @search
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_xpath(@xpath, text: "Cortex")
  end

  it "return no results when appropriate" do
    select I18n.t("ireland.prov.ulster"), from: I18n.t("club.province")
    fill_in I18n.t("club.name"), with: "Aer"
    click_button @search
    expect(page).to_not have_xpath(@xpath)
    expect(page).to have_css("div.alert-warning", text: "No matches")
  end

  it "remember last search" do
    fill_in I18n.t("club.name"), with: "Aer"
    click_button @search
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
      name:      "Bangor",
      web:       "http://chess.bangor.net",
      meet:      "7pm Tuesdays and Thursdays",
      address:   "McKee Clock",
      district:  "Marina",
      city:      "Bangor",
      county:    "down",
      lat:       54.65654,
      long:      -5.67529,
      contact:   "Mark Orr",
      email:     "mark@bangor.net",
      phone:     "07968 537010",
      active:    true,
    }
    bangor = FactoryGirl.create(:club, params)
    visit club_path(bangor)
    params.each do |param, value|
      case param
      when :name
        expect(page).to have_xpath(xpath(I18n.t("club.#{param}")), text: bangor.name)
      when :web
        expect(page).to have_xpath(xpath(I18n.t("club.#{param}")), text: bangor.web_simple)
      when :county
        expect(page).to have_xpath(xpath(I18n.t("club.#{param}")), text: I18n.t("ireland.co.#{value}"))
      when :active
        expect(page).to have_xpath(xpath(I18n.t("club.#{param}")), text: I18n.t(value ? "yes" : "no"))
      else
        expect(page).to have_xpath(xpath(I18n.t("club.#{param}")), text: value)
      end
    end
  end
end
