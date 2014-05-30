require 'spec_helper'

describe "Authorization for logins" do
  let(:ok_roles)        { %w[admin] }
  let(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) }.append("guest") }
  let(:record)          { create(:login) }
  let(:paths)           { [admin_logins_path, admin_login_path(record)] }
  let(:success)         { "div.alert-success" }
  let(:failure)         { "div.alert-danger" }
  let(:unauthorized)    { I18n.t("errors.alerts.unauthorized") }

  it "some roles can view the logins list" do
    ok_roles.each do |role|
      login role
      paths.each do |path|
        visit path
        expect(page).to_not have_css(failure)
      end
    end
  end

  it "other roles and guests cannot" do
    not_ok_roles.each do |role|
      login role
      paths.each do |path|
        visit path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end
end

describe "Listing logins" do
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
    select "Success", from: "Result"
    fill_in "Email", with: @user[:normal].email
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    click_link @user[:normal].email
  end

  it "specific IP" do
    select "Success", from: "Result"
    fill_in "IP", with: @login.ip
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    expect(page).to have_content(@user[:ip].email)
  end

  it "specific results" do
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
