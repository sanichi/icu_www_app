require 'rails_helper'

describe Club do
  include_context "features"

  let(:country)  { I18n.t("club.county") }
  let(:province) { I18n.t("club.province") }

  context "search" do
    before(:each) do
      create(:club, name: "Bangor", city: "Groomsport", contact: "Mark", county: "down")
      create(:club, name: "Bray/Greystones", city: "Dublin", contact: "Mervyn", county: "dublin")
      create(:club, name: "Aer Lingus", city: "Dublin", contact: "Gearóidín", county: "dublin")
      create(:club, name: "Cortex", city: "Arklow", contact: "Danny", county: "wicklow", active: false)
      visit clubs_path
      @row = "//div[starts-with(@id,'club_')]"
      @search = "Search"
    end

    it "shows all active records by default" do
      expect(page).to have_xpath(@row, count: 3)
    end

    it "find records by name" do
      fill_in name, with: "Lingus"
      click_button @search
      expect(page).to have_xpath(@row, count: 1)
      expect(page).to have_xpath(@row, text: "Aer Lingus")
      fill_in name, with: "b"
      click_button @search
      expect(page).to have_xpath(@row, count: 2)
      expect(page).to have_xpath(@row, text: "Bangor")
      expect(page).to have_xpath(@row, text: "Bray/Greystones")
      fill_in name, with: "/"
      click_button @search
      expect(page).to have_xpath(@row, count: 1)
      expect(page).to have_xpath(@row, text: "Bray/Greystones")
    end

    it "find records by city" do
      fill_in city, with: "Dub"
      click_button @search
      expect(page).to have_xpath(@row, count: 2)
      expect(page).to have_xpath(@row, text: "Bray/Greystones")
      expect(page).to have_xpath(@row, text: "Aer Lingus")
    end

    it "find records by county" do
      select "Dublin", from: country
      click_button @search
      expect(page).to have_xpath(@row, count: 2)
      expect(page).to have_xpath(@row, text: "Bray/Greystones")
      expect(page).to have_xpath(@row, text: "Aer Lingus")
      select "Down", from: country
      click_button @search
      expect(page).to have_xpath(@row, count: 1)
      expect(page).to have_xpath(@row, text: "Bangor")
    end

    it "find records by province" do
      select "Lein", from: province
      click_button @search
      expect(page).to have_xpath(@row, count: 2)
      expect(page).to have_xpath(@row, text: "Bray/Greystones")
      expect(page).to have_xpath(@row, text: "Aer Lingus")
      select "Ulster", from: province
      click_button @search
      expect(page).to have_xpath(@row, count: 1)
      expect(page).to have_xpath(@row, text: "Bangor")
    end

    it "find records by whether active or not" do
      select either, from: active
      click_button @search
      expect(page).to have_xpath(@row, count: 4)
      select active, from: active
      click_button @search
      expect(page).to have_xpath(@row, count: 3)
      select inactive, from: active
      click_button @search
      expect(page).to have_xpath(@row, count: 1)
      expect(page).to have_xpath(@row, text: "Cortex")
    end

    it "return no results when appropriate" do
      select "Ulster", from: province
      fill_in name, with: "Aer"
      click_button @search
      expect(page).to_not have_xpath(@row)
      expect(page).to have_css("div.alert-warning", text: "No matches")
    end

    it "remember last search" do
      fill_in name, with: "Aer"
      click_button @search
      expect(page).to have_xpath(@row, count: 1)
      click_link "Aer Lingus"
      click_link last_search
      expect(page).to have_xpath(@row, count: 1)
    end
  end

  context "show" do
    def xpath(label)
      %Q{//table//th[.="#{label}"]/following-sibling::td}
    end

    it "all fields" do
      params = {
        name:      "Bangor",
        web:       "http://chess.bangor.net/",
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
      bangor = create(:club, params)
      visit club_path(bangor)
      params.each do |param, value|
        label = %i(active address city contact email name).include?(param) ? I18n.t(param) : I18n.t("club.#{param}")
        case param
        when :name
          expect(page).to have_css("h1", text: bangor.name)
        when :web
          expect(page).to have_xpath(xpath(label), text: "chess.bangor.net")
        when :county
          expect(page).to have_xpath(xpath(label), text: I18n.t("ireland.co.#{value}"))
        when :active
          expect(page).to have_xpath(xpath(label), text: I18n.t(value ? "yes" : "no"))
        else
          expect(page).to have_xpath(xpath(label), text: value)
        end
      end
    end
  end

  context "previous and next links" do
    11.times do |i|
      let!("club#{i}".to_sym) { create(:club, name: "Club #{(i + 65).chr}", lat: nil, long: nil) }
    end

    let(:header)    { "h1" }
    let(:prev_link) { "☜" }
    let(:next_link) { "☞" }

    it "first few" do
      visit clubs_path
      click_link club0.name

      expect(page).to have_css(header, text: club0.name)
      click_link next_link

      expect(page).to have_css(header, text: club1.name)
      click_link next_link

      expect(page).to have_css(header, text: club2.name)
      expect(page).to have_link(next_link)
      click_link prev_link

      expect(page).to have_css(header, text: club1.name)
      click_link prev_link

      expect(page).to have_css(header, text: club0.name)
      expect(page).to_not have_link(prev_link)
    end

    it "last few" do
      visit clubs_path
      click_link club8.name

      expect(page).to have_css(header, text: club8.name)
      click_link next_link

      expect(page).to have_css(header, text: club9.name)
      click_link next_link

      expect(page).to have_button(search)
      click_link club10.name

      expect(page).to_not have_link(next_link)
      click_link prev_link

      expect(page).to have_button(search)
      click_link club9.name

      expect(page).to have_css(header, text: club9.name)
      click_link prev_link

      expect(page).to have_css(header, text: club8.name)
      expect(page).to have_link(prev_link)
    end

    it "only enough for one page" do
      club10.destroy
      visit clubs_path

      visit club_path(club0)
      expect(page).to have_css(header, text: club0.name)
      expect(page).to_not have_link(prev_link)
      expect(page).to have_link(next_link)

      visit club_path(club9)
      expect(page).to have_css(header, text: club9.name)
      expect(page).to have_link(prev_link)
      expect(page).to_not have_link(next_link)
    end

    it "one is destroyed after the search is saved" do
      visit clubs_path

      visit club_path(club3)
      expect(page).to have_css(header, text: club3.name)
      expect(page).to have_link(prev_link)
      expect(page).to have_link(next_link)

      visit club_path(club5)
      expect(page).to have_css(header, text: club5.name)
      expect(page).to have_link(prev_link)
      expect(page).to have_link(next_link)

      club4.destroy

      visit club_path(club3)
      expect(page).to have_css(header, text: club3.name)
      expect(page).to have_link(prev_link)
      expect(page).to_not have_link(next_link)

      visit club_path(club5)
      expect(page).to have_css(header, text: club5.name)
      expect(page).to_not have_link(prev_link)
      expect(page).to have_link(next_link)
    end

    it "none without a search" do
      visit club_path(club3)

      expect(page).to_not have_link(prev_link)
      expect(page).to_not have_link(next_link)
    end
  end
end
