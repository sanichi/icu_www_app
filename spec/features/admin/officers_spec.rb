require 'rails_helper'

describe Officer do
  include_context "features"

  context "authorization" do
    let!(:admin)   { create(:officer, rank: 1, role: "webmaster") }
    let!(:ratings) { create(:officer, rank: 2, role: "ratings") }
    let!(:chair)   { create(:officer, rank: 3, role: "chairperson") }
    let!(:vice)    { create(:officer, rank: 4, role: "vicechairperson") }
    let!(:pro)     { create(:officer, rank: 5, role: "publicrelations") }

    let(:level1)   { %w[admin] }
    let(:level2)   { User::ROLES.reject { |role| level1.include?(role) }.append("guest") }

    let(:header)   { "h1" }

    it "level 1 can index, view and edit" do
      level1.each do |role|
        login role
        visit admin_officers_path
        expect(page).to_not have_css(failure)
        visit admin_officer_path(ratings)
        expect(page).to_not have_css(failure)
        expect(page).to have_css(header, text: "Rating Officer")
        expect(page).to have_link(edit)
        visit edit_admin_officer_path(chair)
        expect(page).to_not have_css(failure)
      end
    end

    it "level 2 can't do anything" do
      level2.each do |role|
        login role
        visit admin_officers_path
        expect(page).to have_css(failure, text: unauthorized)
        visit admin_officer_path(ratings)
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_officer_path(chair)
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end
end
