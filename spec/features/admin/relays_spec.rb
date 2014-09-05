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
end
