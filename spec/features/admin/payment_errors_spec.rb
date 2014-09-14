require 'rails_helper'

describe PaymentError do
  include_context "features"

  context "authorisation" do
    let(:level1) { %w[admin treasurer] }
    let(:level2) { User::ROLES.reject { |role| level1.include?(role) }.append("guest") }
    let(:paths)  { [admin_payment_errors_path] }

    it "level 1 can index payment errors" do
      level1.each do |role|
        login role
        paths.each do |path|
          visit path
          expect(page).to_not have_css(failure)
        end
      end
    end

    it "level 2 cannot" do
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
