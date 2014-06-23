require 'rails_helper'

describe Login do;
  include_context "features"

  context "authorization" do
    let(:level1) { %w[admin] }
    let(:level2) { User::ROLES.reject { |role| level1.include?(role) }.append("guest") }
    let(:record) { create(:login) }
    let(:paths)  { [admin_logins_path, admin_login_path(record)] }

    it "level 1 can view the logins list" do
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

  context "index" do
    let(:ip)     { "IP" }
    let(:result) { "Result" }

    before(:each) do
      @user = {}
      @user[:normal]     = login "user"
      @user[:roles]      = login create(:user, roles: "translator")
      @user[:expired]    = login create(:user, expires_on: Date.today.years_ago(2).end_of_year)
      @user[:unverified] = login create(:user, verified_at: nil)
      @user[:status]     = login create(:user, status: "Undesirable")
      @user[:password]   = login create(:user), password: "wrong password"
      @user[:ip]         = create(:user)
      @login             = create(:login, user: @user[:ip], ip: "198.168.0.1")
      @user[:admin]      = login "admin"
      visit admin_logins_path
      @xpath = "//table[@id='results']/tbody/tr"
    end

    it "specific email" do
      select "Success", from: result
      fill_in email, with: @user[:normal].email
      click_button search
      expect(page).to have_xpath(@xpath, count: 1)
      click_link @user[:normal].email
    end

    it "specific IP" do
      select "Success", from: result
      fill_in ip, with: @login.ip
      click_button search
      expect(page).to have_xpath(@xpath, count: 1)
      expect(page).to have_content(@user[:ip].email)
    end

    it "specific results" do
      select "Failure", from: result
      click_button search
      expect(page).to have_xpath(@xpath, count: 4)

      select "Bad password", from: result
      click_button search
      expect(page).to have_xpath(@xpath, count: 1)
      expect(page).to have_content(@user[:password].email)

      select "Disabled", from: result
      click_button search
      expect(page).to have_xpath(@xpath, count: 1)
      expect(page).to have_content(@user[:status].email)

      select "Unverified", from: result
      click_button search
      expect(page).to have_xpath(@xpath, count: 1)
      expect(page).to have_content(@user[:unverified].email)

      select "Expired", from: result
      click_button search
      expect(page).to have_xpath(@xpath, count: 1)
      expect(page).to have_content(@user[:expired].email)

      select "Success", from: result
      click_button search
      expect(page).to have_xpath(@xpath, count: 4)

      select "Any", from: result
      click_button search
      expect(page).to have_xpath(@xpath, count: @user.size)
    end
  end
end
