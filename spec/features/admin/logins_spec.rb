require 'spec_helper'

feature "Authorization for logins" do
  given(:non_admin_roles) { User::ROLES.reject{ |role| role == "admin" } }
  given(:record)          { create(:login) }
  given(:paths)           { [admin_logins_path, admin_login_path(record)] }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:unauthorized)    { I18n.t("errors.messages.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }

  scenario "admin users can view the logins list" do
    logout
    login "admin"
    expect(page).to have_css(success, text: signed_in_as)
    paths.each do |path|
      visit path
      expect(page).to_not have_css(failure)
    end
  end

  scenario "non-admin cannot view the logins list" do
    non_admin_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      paths.each do |path|
        visit path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end

  scenario "guests cannot view the logins list" do
    logout
    paths.each do |path|
      visit path
      expect(page).to have_css(failure, text: unauthorized)
    end
  end
end

feature "Listing logins" do
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

  scenario "specific email" do
    select "Success", from: "Result"
    fill_in "Email", with: @user[:normal].email
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    click_link @user[:normal].email
  end

  scenario "specific IP" do
    select "Success", from: "Result"
    fill_in "IP", with: @login.ip
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_content(@user[:ip].email)
  end

  scenario "specific results" do
    select "Failure", from: "Result"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 4)

    select "Bad password", from: "Result"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_content(@user[:password].email)

    select "Disabled", from: "Result"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_content(@user[:status].email)

    select "Unverified", from: "Result"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_content(@user[:unverified].email)

    select "Expired", from: "Result"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_content(@user[:expired].email)

    select "Success", from: "Result"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 4)

    select "Any", from: "Result"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: @user.size)
  end
end
