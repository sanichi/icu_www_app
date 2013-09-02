require 'spec_helper'

feature "Sessions" do
  background(:each) do
    visit "/sign_in"
  end

  given(:user) { FactoryGirl.create(:user) }
  given(:password) { "password" }
  given(:bad_password) { "drowssap" }
  given(:ip) { "127.0.0.1" }
  given(:admin_role) { "admin" }
  given(:non_admin_roles) { User::ROLES.reject{ |role| role == "admin" }.sample(2).sort.join(" ") }

  scenario "arriving at the sign in page" do
    expect(page).to have_title("Sign in")
    expect(page).to have_xpath("//form//input[@name='email']")
    expect(page).to have_xpath("//form//input[@name='password']")
  end

  scenario "signing in and signing out" do
    page.fill_in "Email", with: user.email
    page.fill_in "Password", with: password
    click_button "Sign in"
    expect(page).to have_title("Irish Chess Union")
    expect(page).to have_css("div.alert-success", text: "Signed in as")
    expect(Login.count).to eq(1)
    expect(user.logins.where(error: nil, email: nil, ip: ip, roles: nil).count).to eq(1)
    click_link "Sign out"
    expect(page).to have_title("Sign in")
    expect(page).to have_xpath("//form//input[@name='email']")
  end

  scenario "entering an invalid email" do
    bad_email = "bad." + user.email
    page.fill_in "Email", with: bad_email
    page.fill_in "Password", with: "password"
    click_button "Sign in"
    expect(page).to have_title("Sign in")
    expect(page).to have_css("div.alert-danger", text: "Invalid email or password")
    expect(Login.count).to eq(1)
    expect(Login.where(user_id: nil, email: bad_email, error: "invalid_details", ip: ip, roles: nil).count).to eq(1)
  end

  scenario "entering an invalid password" do
    page.fill_in "Email", with: user.email
    page.fill_in "Password", with: bad_password
    click_button "Sign in"
    expect(page).to have_title("Sign in")
    expect(page).to have_css("div.alert-danger", text: "Invalid email or password")
    expect(Login.count).to eq(1)
    expect(user.logins.where(email: nil, error: "invalid_details", ip: ip, roles: nil).count).to eq(1)
  end

  scenario "the user's subscription has expired" do
    user = FactoryGirl.create(:user, expires_on: 1.year.ago.at_end_of_year)
    page.fill_in "Email", with: user.email
    page.fill_in "Password", with: "password"
    click_button "Sign in"
    page.should have_title("Sign in")
    page.should have_selector("div.alert-danger", text: "Subscription expired")
    expect(Login.count).to eq(1)
    expect(user.logins.where(email: nil, error: "subscription_expired", ip: ip, roles: nil).count).to eq(1)
  end

  it "recording the user's current role" do
    page.fill_in "Email", with: user.email
    page.fill_in "Password", with: password
    click_button "Sign in"
    visit "/sign_out"
    user.roles = admin_role
    user.save
    page.fill_in "Email", with: user.email
    page.fill_in "Password", with: password
    click_button "Sign in"
    visit "/sign_out"
    page.fill_in "Email", with: user.email
    page.fill_in "Password", with: password
    click_button "Sign in"
    visit "/sign_out"
    user.roles = non_admin_roles
    user.save
    page.fill_in "Email", with: user.email
    page.fill_in "Password", with: password
    click_button "Sign in"
    expect(Login.count).to eq(4)
    expect(user.logins.count).to eq(4)
    expect(user.logins.where(error: nil, roles: nil, ip: ip).count).to eq(1)
    expect(user.logins.where(error: nil, roles: admin_role, ip: ip).count).to eq(2)
    expect(user.logins.where(error: nil, roles: non_admin_roles, ip: ip).count).to eq(1)
  end
end
