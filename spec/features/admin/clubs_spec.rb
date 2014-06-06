require 'spec_helper'

describe Club do;
  include_context "features"

  let(:contact)       { I18n.t("club.contact") }
  let(:county)        { I18n.t("club.county") }
  let(:district)      { I18n.t("club.district") }
  let(:latitude)      { I18n.t("club.lat") }
  let(:longitude)     { I18n.t("club.long") }
  let(:meetings)      { I18n.t("club.meet") }
  let(:phone)         { I18n.t("club.phone") }
  let(:please_select) { I18n.t("please_select") }
  let(:website)       { I18n.t("club.web") }

  context "authorization" do
    let(:club)   { create(:club) }
    let(:header) { "//h1[.='#{club.name}']" }
    let(:level1) { %w[admin editor] }
    let(:level2) { User::ROLES.reject { |role| level1.include?(role) }.append("guest") }

    it "level 1 can manage clubs as well as view" do
      level1.each do |role|
        login role
        visit new_admin_club_path
        expect(page).to_not have_css(failure)
        visit edit_admin_club_path(club)
        expect(page).to_not have_css(failure)
        visit club_path(club)
        expect(page).to have_xpath(header)
        expect(page).to have_link(edit)
      end
    end

    it "level 2 can only view" do
      level2.each do |role|
        login role
        visit new_admin_club_path
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_club_path(club)
        expect(page).to have_css(failure, text: unauthorized)
        visit club_path(club)
        expect(page).to have_xpath(header)
        expect(page).to_not have_link(edit)
      end
    end
  end

  context "create" do
    before(:each) do
      login "editor"
    end

    it "sucessful creation with all attributes" do
      click_link "New Club"
      fill_in name, with: "Bangor"
      fill_in website, with: "www.ulsterchess.org/membership/Clubs/bangor"
      fill_in meetings, with: "Thursdays"
      fill_in address, with: "The Pub"
      fill_in district, with: "Groomsport"
      fill_in city, with: "Bangor"
      select "Down", from: county
      fill_in latitude, with: 54.67301
      fill_in longitude, with: -5.61431
      fill_in contact, with: "Eddie Webb"
      fill_in email, with: "eddie.webb@heaven.com"
      fill_in phone, with: "02891 1234 567"
      check active
      click_button save

      expect(page).to have_css(success, text: created)
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

    it "sucessful creation with minimal attributes" do
      click_link "New Club"
      fill_in name, with: "Millisle"
      fill_in city, with: "Millisle"
      select "Down", from: county
      uncheck active
      click_button save

      expect(page).to have_css(success, text: created)
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

  context "edit" do
    before(:each) do
      @bangor = create(:club)
      login "editor"
      visit edit_admin_club_path(@bangor)
    end

    it "name is mandatory" do
      fill_in name, with: ""
      click_button save
      expect(page).to have_css(field_error, text: "blank")
    end

    it "city is mandatory" do
      fill_in city, with: ""
      click_button save
      expect(page).to have_css(field_error, text: "blank")
    end

    it "county is mandatory" do
      select please_select, from: county
      click_button save
      expect(page).to have_css(field_error, text: "invalid")
    end

    it "at least one contact method is mandadory for an active club" do
      fill_in website, with: ""
      fill_in email, with: ""
      fill_in phone, with: ""
      click_button save
      expect(page).to have_css(failure, text: "contact")
      uncheck active
      click_button save
      expect(page).to have_css(success)
    end
  end
end
