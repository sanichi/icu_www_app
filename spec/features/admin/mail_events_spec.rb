require 'rails_helper'

describe MailEvent do
  include_context "features"

  context "authorization" do
    let(:level1) { %w[admin] }
    let(:level2) { User::ROLES.reject { |role| level1.include?(role) }.append("guest") }

    it "level 1 can index mail events" do
      level1.each do |role|
        login role
        visit admin_mail_events_path
        expect(page).to_not have_css(failure)
      end
    end

    it "level 2 cannot" do
      level2.each do |role|
        login role
        visit admin_mail_events_path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end
end
