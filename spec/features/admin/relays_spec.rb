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
    let!(:ecu)      { create(:officer, role: "ecu", rank: 2, active: false) }
    let!(:fide)     { create(:officer, role: "fide", rank: 2, active: false) }

    let!(:relay) { %i[ecu fide ratings].each_with_object({}){ |r, h| h[r] = create(:relay, from: "#{r}@icu.ie", officer: nil) } }

    let(:officer)  { I18n.t("officer.officer") }
    let(:officers) { I18n.t("officer.officers") }
    let(:relays)   { I18n.t("relay.relays") }
    let(:role)     { %i[ratings fide_ecu fide ecu].each_with_object({}){ |r, h| h[r] = I18n.t("officer.role.#{r}") } }

    before(:each) do
      login("admin")
    end

    it "one relay per officer" do
      expect(ratings.emails.size).to eq 0

      visit admin_relays_path
      click_link relay[:ratings].from
      click_link edit

      select role[:ratings], from: officer
      click_button save
      expect(page).to have_css(success)

      ratings.reload
      expect(ratings.emails.size).to eq 1
      expect(ratings.emails.first).to eq relay[:ratings].from

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
      click_link relay[:fide].from
      click_link edit

      select role[:fide_ecu], from: officer
      click_button save
      expect(page).to have_css(success)

      visit admin_relays_path
      click_link relay[:ecu].from
      click_link edit

      select role[:fide_ecu], from: officer
      click_button save
      expect(page).to have_css(success)

      fide_ecu.reload
      expect(fide_ecu.emails.size).to eq 2
      expect(fide_ecu.emails.first).to eq relay[:ecu].from
      expect(fide_ecu.emails.last).to eq relay[:fide].from
    end

    it "split one officer into two" do
      expect(ecu.active).to eq false
      expect(fide.active).to eq false
      expect(fide_ecu.active).to eq true

      click_link officers
      click_link role[:fide_ecu]
      click_link edit
      uncheck active
      click_button save

      click_link officers
      click_link role[:ecu]
      click_link edit
      check active
      click_button save

      click_link officers
      click_link role[:fide]
      click_link edit
      check active
      click_button save

      visit admin_relays_path
      click_link relay[:fide].from
      click_link edit
      select role[:fide], from: officer
      click_button save
      expect(page).to have_css(success)

      visit admin_relays_path
      click_link relay[:ecu].from
      click_link edit
      select role[:ecu], from: officer
      click_button save
      expect(page).to have_css(success)

      ecu.reload
      fide.reload
      fide_ecu.reload

      expect(ecu.active).to eq true
      expect(fide.active).to eq true
      expect(fide_ecu.active).to eq false

      expect(ecu.emails.size).to eq 1
      expect(fide.emails.size).to eq 1
      expect(fide_ecu.emails).to be_empty

      expect(ecu.emails.first).to eq relay[:ecu].from
      expect(fide.emails.first).to eq relay[:fide].from
    end
  end
end
