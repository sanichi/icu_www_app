require 'rails_helper'

describe Relay do
  include_context "features"

  context "authorization" do
    let!(:relay)   { create(:relay) }
    let(:level1)   { %w[admin] }
    let(:level2)   { User::ROLES.reject { |role| level1.include?(role) }.append("guest") }

    let(:header)   { "h1" }

    it "level 1 can index, view, edit" do
      level1.each do |role|
        login role
        visit admin_relays_path
        expect(page).to_not have_css(failure)
        visit admin_relay_path(relay)
        expect(page).to_not have_css(failure)
        expect(page).to have_css(header, text: relay.from)
        expect(page).to have_link(edit)
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
        visit edit_admin_relay_path(relay)
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end

  context "edit" do
    let!(:ratings)  { create(:officer, role: "ratings", rank: 1, executive: false) }
    let!(:fide_ecu) { create(:officer, role: "fide_ecu", rank: 2) }

    let!(:ecu)  { create(:relay, from: "ecu@icu.ie", officer: nil) }
    let!(:fide) { create(:relay, from: "fide@icu.ie", officer: nil) }
    let!(:rat)  { create(:relay, from: "ratings@icu.ie", officer: nil) }

    let(:roles) { %w[ratings fide_ecu].map { |r| I18n.t("officer.role.#{r}") } }
    let(:officer) { I18n.t("officer.officer") }

    before(:each) do
      login("admin")
    end

    it "one relay per officer" do
      expect(ratings.emails.size).to eq 0

      visit admin_relays_path
      click_link rat.from
      click_link edit

      select roles[0], from: officer
      click_button save
      expect(page).to have_css(success)

      ratings.reload
      expect(ratings.emails.size).to eq 1
      expect(ratings.emails.first).to eq rat.from

      click_link edit

      select none, from: officer
      click_button save
      expect(page).to have_css(success)

      ratings.reload
      expect(ratings.emails).to be_empty
    end

    it "two relays per officer" do
      expect(fide_ecu.emails.size).to eq 0

      visit admin_relays_path
      click_link fide.from
      click_link edit

      select roles[1], from: officer
      click_button save
      expect(page).to have_css(success)

      visit admin_relays_path
      click_link ecu.from
      click_link edit

      select roles[1], from: officer
      click_button save
      expect(page).to have_css(success)

      fide_ecu.reload
      expect(fide_ecu.emails.size).to eq 2
      expect(fide_ecu.emails.first).to eq ecu.from
      expect(fide_ecu.emails.last).to eq fide.from
    end
  end
end
