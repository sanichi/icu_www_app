require 'rails_helper'

describe BadLogin do
  include_context "features"

  context "authorization" do
    let(:level1) { %w[admin] }
    let(:level2) { User::ROLES.reject{ |r| level1.include?(r) }.append("guest") }

    it "level 1 can view the list" do
      level1.each do |role|
        login role
        visit admin_bad_logins_path
        expect(page).to_not have_css(failure)
      end
    end

    it "level 2 cannot view the list" do
      level2.each do |role|
        login role
        visit admin_bad_logins_path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end

  context "index" do
    let(:password)     { I18n.t("user.password") }
    let(:sign_in)      { I18n.t("session.sign_in") }

    let(:bad_email)    { "baddy@hacker.net" }
    let(:bad_password) { "password" }
    let(:ip)           { "127.0.0.1" }

    before(:each) do
      visit sign_in_path
      fill_in email, with: bad_email
      fill_in password, with: bad_password
      click_button sign_in
      login "admin"
      visit admin_bad_logins_path
    end

    def xpath(text)
      %Q{//table[@id="results"]/tbody/tr/td[.="#{text}"]}
    end

    it "shows user, encryted password and IP" do
      expect(page).to have_xpath(xpath(bad_email), count: 1)
      expect(page).to have_xpath(xpath(Digest::MD5.hexdigest(bad_password)), count: 1)
      expect(page).to have_xpath(xpath(ip), count: 1)
    end
  end
end
