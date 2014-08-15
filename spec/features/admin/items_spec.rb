require 'rails_helper'

describe Item do
  include_context "features"

  context "authorization" do
    let(:level1) { ["admin", "treasurer"] }
    let(:level2) { User::ROLES.reject { |r| level1.include?(r) } }
    let(:level3) { ["guest"] }

    it "level 1 can index items and show ledger" do
      level1.each do |role|
        login role
        visit admin_items_path
        expect(page).to_not have_css(failure)
        visit sales_ledger_admin_items_path
        expect(page).to_not have_css(failure)
      end
    end

    it "level 2 can show ledger" do
      level2.each do |role|
        login role
        visit admin_items_path
        expect(page).to have_css(failure, text: unauthorized)
        visit sales_ledger_admin_items_path
        expect(page).to_not have_css(failure)
      end
    end

    it "level 3 can do nothing" do
      level3.each do |role|
        login role
        visit admin_items_path
        expect(page).to have_css(failure, text: unauthorized)
        visit sales_ledger_admin_items_path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end
end
