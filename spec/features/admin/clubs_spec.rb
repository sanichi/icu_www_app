# encoding: utf-8
require 'spec_helper'

feature "Authorization for clubs" do
  given(:ok_roles)        { %w[admin editor] }
  given(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) } }
  given(:club)            { FactoryGirl.create(:club) }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:header)          { "//th[.='Name']/following-sibling::td[.='#{club.name}']" }
  given(:button)          { I18n.t("edit") }
  given(:unauthorized)    { I18n.t("errors.messages.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }

  scenario "the admin and editor roles can manage clubs" do
    ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      visit new_admin_club_path
      expect(page).to_not have_css(failure)
      visit edit_admin_club_path(club)
      expect(page).to_not have_css(failure)
      visit club_path(club)
      expect(page).to have_xpath(header)
      expect(page).to have_link(button)
    end
  end

  scenario "other roles cannot manage clubs" do
    not_ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      visit new_admin_club_path
      expect(page).to have_css(failure, text: unauthorized)
      visit edit_admin_club_path(club)
      expect(page).to have_css(failure, text: unauthorized)
      visit club_path(club)
      expect(page).to have_xpath(header)
      expect(page).to_not have_link(button)
    end
  end

  scenario "guests cannot manage clubs" do
    logout
    visit new_admin_club_path
    expect(page).to have_css(failure, text: unauthorized)
    visit edit_admin_club_path(club)
    expect(page).to have_css(failure, text: unauthorized)
    visit club_path(club)
    expect(page).to have_xpath(header)
    expect(page).to_not have_link(button)
  end
end

feature "New clubs" do
  before(:each) do
    login("editor")
  end

  given(:success) { "div.alert-success" }

  scenario "sucessful creation with all attributes" do
    click_link "New Club"
    fill_in "Name", with: "Bangor"
    fill_in "Website", with: "www.ulsterchess.org/membership/Clubs/bangor"
    fill_in "Meetings", with: "Thursdays"
    fill_in "Address", with: "The Pub"
    fill_in "District", with: "Groomsport"
    fill_in "City", with: "Bangor"
    select "Down", from: "County"
    fill_in "Latitude", with: 54.67301
    fill_in "Longitude", with: -5.61431
    fill_in "Contact", with: "Eddie Webb"
    fill_in "Email", with: "eddie.webb@heaven.com"
    fill_in "Phone", with: "02891 1234 567"
    select "Active", from: "Active"
    click_button "Save"
    expect(page).to have_css(success, text: "created")
    club = Club.last
    expect(club.name).to eq "Bangor"
    expect(club.web).to eq "http://www.ulsterchess.org/membership/Clubs/bangor"
    expect(club.meet).to eq "Thursdays"
    expect(club.address).to eq "The Pub"
    expect(club.district).to eq "Groomsport"
    expect(club.city).to eq "Bangor"
    expect(club.county).to eq "down"
    expect(club.province).to eq "ulster"
    expect(club.lat).to be_within(0.00001).of(54.67301)
    expect(club.long).to be_within(0.00001).of(-5.61431)
    expect(club.contact).to eq "Eddie Webb"
    expect(club.email).to eq "eddie.webb@heaven.com"
    expect(club.phone).to eq "02891 1234 567"
    expect(club.active).to eq true
  end

  scenario "sucessful creation with minimal attributes" do
    click_link "New Club"
    fill_in "Name", with: "Millisle"
    fill_in "City", with: "Millisle"
    select "Down", from: "County"
    select "Inactive", from: "Active"
    click_button "Save"
    expect(page).to have_css(success, text: "created")
    club = Club.last
    expect(club.name).to eq "Millisle"
    expect(club.web).to be_nil
    expect(club.meet).to be_nil
    expect(club.address).to be_nil
    expect(club.district).to be_nil
    expect(club.city).to eq "Millisle"
    expect(club.county).to eq "down"
    expect(club.province).to eq "ulster"
    expect(club.lat).to be_nil
    expect(club.long).to be_nil
    expect(club.contact).to be_nil
    expect(club.email).to be_nil
    expect(club.phone).to be_nil
    expect(club.active).to eq false
  end
end

feature "Editing clubs" do
  before(:each) do
    @bangor = FactoryGirl.create(:club)
    login("editor")
    visit edit_admin_club_path(@bangor)
  end

  given(:success)      { "div.alert-success" }
  given(:base_failure) { "div.alert-danger" }
  given(:attr_failure) { "div.help-block" }

  scenario "name is mandatory" do
    fill_in "Name", with: ""
    click_button "Save"
    expect(page).to have_css(attr_failure, text: "blank")
  end

  scenario "city is mandatory" do
    fill_in "City", with: ""
    click_button "Save"
    expect(page).to have_css(attr_failure, text: "blank")
  end

  scenario "county is mandatory" do
    select "Please select", from: "County"
    click_button "Save"
    expect(page).to have_css(attr_failure, text: "invalid")
  end

  scenario "at least one contact method is mandadory for an active club" do
    fill_in "Website", with: ""
    fill_in "Email", with: ""
    fill_in "Phone", with: ""
    click_button "Save"
    expect(page).to have_css(base_failure, text: "contact")
    select "Inactive", from: "Active"
    click_button "Save"
    expect(page).to have_css(success)
  end
end
