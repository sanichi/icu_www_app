require 'rails_helper'

describe Relay do
  include_context "features"

  context "authorization" do
    let!(:relay)   { create(:relay) }
    let(:level1)   { %w[admin] }
    let(:level2)   { User::ROLES.reject { |role| level1.include?(role) }.append("guest") }

    let(:header)   { "h1" }

    it "level 1 can index, view, create, edit" do
      level1.each do |role|
        login role
        visit admin_relays_path
        expect(page).to_not have_css(failure)
        visit admin_relay_path(relay)
        expect(page).to_not have_css(failure)
        expect(page).to have_css(header, text: relay.from)
        expect(page).to have_link(edit)
        expect(page).to have_link(delete)
        visit new_admin_relay_path
        expect(page).to_not have_css(failure)
        visit edit_admin_relay_path(relay)
        expect(page).to_not have_css(failure)
      end
    end

    it "level 2 can't do anything" do
      level2.each do |role|
        login role
        visit admin_relays_path
        expect(page).to have_css(failure, text: unauthorized)
        visit admin_relay_path(relay)
        expect(page).to have_css(failure, text: unauthorized)
        visit new_admin_relay_path
        expect(page).to have_css(failure)
        visit edit_admin_relay_path(relay)
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end
  
  context "create" do
    let!(:webmaster) { create(:officer, role: "webmaster", rank: 1, executive: false) }
    let!(:ratings)   { create(:officer, role: "ratings", rank: 2) }
    
    let(:from)    { I18n.t("relay.from") }
    let(:officer) { I18n.t("officer.officer") }

    let(:roles)  { %w[ratings webmaster].map { |r| I18n.t("officer.role.#{r}") } }
    let(:emails) { %w[ratings webmaster].map { |r| "#{r}@icu.ie" } }
    
    before(:each) do
      login("admin")
    end
    
    it "one relay per officer" do
      visit admin_relays_path
      click_link new_one
      
      fill_in from, with: emails[0]
      select roles[0], from: officer
      click_button save  
      expect(page).to have_css(success)

      expect(ratings.emails.size).to eq 1
      expect(ratings.emails.first).to eq emails[0]
    end

    it "two relays per officer" do
      visit admin_relays_path
      click_link new_one
      
      fill_in from, with: emails[0]
      select roles[1], from: officer
      click_button save
      expect(page).to have_css(success)

      visit admin_relays_path
      click_link new_one

      fill_in from, with: emails[1]
      select roles[1], from: officer
      click_button save
      expect(page).to have_css(success)

      expect(webmaster.emails.size).to eq 2
      expect(webmaster.emails.first).to eq emails[0]
      expect(webmaster.emails.last).to eq emails[1]
    end
  end
end
