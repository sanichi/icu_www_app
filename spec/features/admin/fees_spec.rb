require 'rails_helper'

describe Fee do;
  include_context "features"

  context "authorization" do
    let(:fee)    { create(:subscription_fee) }
    let(:level1) { %w[admin treasurer] }
    let(:level2) { User::ROLES.reject { |role| level1.include?(role) }.append("guest") }
    let(:paths)  { [admin_fees_path, admin_fee_path(fee), edit_admin_fee_path(fee), new_admin_fee_path, clone_admin_fee_path(fee), rollover_admin_fee_path(fee)] }

    it "level 1 can manage subscription fees" do
      level1.each do |role|
        login role
        paths.each do |path|
          visit path
          expect(page).to_not have_css(failure)
        end
      end
    end

    it "level 2 have no access" do
      level2.each do |role|
        login role
        paths.each do |path|
          visit path
          expect(page).to have_css(failure, text: unauthorized)
        end
      end
    end
  end
end
