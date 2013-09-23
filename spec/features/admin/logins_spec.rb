require 'spec_helper'

feature "Authorization for logins" do
  given(:non_admin_roles) { User::ROLES.reject{ |role| role == "admin" } }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:unauthorized)    { I18n.t("errors.messages.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }

  scenario "admin users can view the logins list" do
    logout
    login("admin")
    expect(page).to have_css(success, text: signed_in_as)
    visit admin_logins_path
    expect(page).not_to have_css(failure)
  end

  scenario "non-admin cannot view the logins list" do
    non_admin_roles.each do |role|
      login(role)
      expect(page).to have_css(success, text: signed_in_as)
      visit admin_logins_path
      expect(page).to have_css(failure, text: unauthorized)
    end
  end

  scenario "guests cannot view the logins list" do
    logout
    visit admin_logins_path
    expect(page).to have_css(failure, text: unauthorized)
  end
end

feature "Listing logins" do
  before(:each) do
    @user = {}
    @user[:normal]     = login("user")
    @user[:roles]      = login(FactoryGirl.create(:user, roles: "translator"))
    @user[:expired]    = login(FactoryGirl.create(:user, expires_on: Date.today.years_ago(2).end_of_year))
    @user[:unverified] = login(FactoryGirl.create(:user, verified_at: nil))
    @user[:status]     = login(FactoryGirl.create(:user, status: "Undesirable"))
    @user[:email]      = login(FactoryGirl.create(:user), email: "wrong@example.com")
    @user[:password]   = login(FactoryGirl.create(:user), password: "wrong password")
    @user[:ip]         = FactoryGirl.create(:user)
    @login             = FactoryGirl.create(:login, user: @user[:ip], ip: "198.168.0.1")
    @user[:admin]      = login("admin")
    visit admin_logins_path
    @xpath = "//table[@id='results']/tbody/tr"
  end

  scenario "specific email" do
    page.select "Success", from: "Result"
    page.fill_in "Email", with: @user[:normal].email
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    click_link @user[:normal].email
  end

  scenario "specific IP" do
    page.select "Success", from: "Result"
    page.fill_in "IP", with: @login.ip
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_content(@user[:ip].email)
  end

  scenario "specific results" do
    page.select "Failure", from: "Result"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 5)

    page.select "Bad email", from: "Result"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_content("wrong@example.com")

    page.select "Bad password", from: "Result"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_content(@user[:password].email)

    page.select "Disabled", from: "Result"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_content(@user[:status].email)

    page.select "Unverified", from: "Result"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_content(@user[:unverified].email)

    page.select "Expired", from: "Result"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_content(@user[:expired].email)

    page.select "Success", from: "Result"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 4)

    page.select "Any", from: "Result"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: @user.size)
  end

  scenario "deleted users" do
    visit admin_user_path(@user[:normal])
    click_link "Delete"
    expect(User.count).to eq(@user.size - 1)
    visit admin_logins_path
    page.select "Success", from: "Result"
    page.select "No user", from: "User"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_content(@user[:normal].email)
  end
end
