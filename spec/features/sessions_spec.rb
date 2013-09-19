require 'spec_helper'

feature "Sessions" do
  background(:each) do
    visit "/sign_in"
  end

  given(:user)            { FactoryGirl.create(:user) }
  given(:password)        { "password" }
  given(:bad_password)    { "drowssap" }
  given(:ip)              { "127.0.0.1" }
  given(:admin_role)      { "admin" }
  given(:non_admin_roles) { User::ROLES.reject{ |role| role == "admin" }.sample(2).sort.join(" ") }
  given(:sign_in_button)  { I18n.t("session.sign_in") }
  given(:sign_in_title)   { I18n.t("session.sign_in") }
  given(:email_text)      { I18n.t("user.email") }
  given(:password_text)   { I18n.t("user.password") }

  scenario "arriving at the sign in page" do
    expect(page).to have_title(sign_in_title)
    expect(page).to have_xpath("//form//input[@name='email']")
    expect(page).to have_xpath("//form//input[@name='password']")
  end

  scenario "signing in and signing out" do
    page.fill_in email_text, with: user.email
    page.fill_in password_text, with: password
    click_button sign_in_button
    expect(page).to have_title(I18n.t("icu"))
    expect(page).to have_css("div.alert-success", text: I18n.t("session.signed_in_as"))
    expect(Login.count).to eq(1)
    expect(user.logins.where(error: nil, email: nil, ip: ip, roles: nil).count).to eq(1)
    click_link "Sign out"
    expect(page).to have_title(sign_in_title)
    expect(page).to have_xpath("//form//input[@name='email']")
  end

  scenario "entering an invalid email" do
    bad_email = "bad." + user.email
    page.fill_in email_text, with: bad_email
    page.fill_in password_text, with: "password"
    click_button sign_in_button
    expect(page).to have_title(sign_in_title)
    expect(page).to have_css("div.alert-danger", text: I18n.t("session.invalid_details"))
    expect(Login.count).to eq(1)
    expect(Login.where(user_id: nil, email: bad_email, error: "invalid_details", ip: ip, roles: nil).count).to eq(1)
  end

  scenario "entering an invalid password" do
    page.fill_in email_text, with: user.email
    page.fill_in password_text, with: bad_password
    click_button sign_in_button
    expect(page).to have_title(sign_in_title)
    expect(page).to have_css("div.alert-danger", text: I18n.t("session.invalid_details"))
    expect(Login.count).to eq(1)
    expect(user.logins.where(email: nil, error: "invalid_details", ip: ip, roles: nil).count).to eq(1)
  end

  scenario "the user's subscription has expired" do
    user = FactoryGirl.create(:user, expires_on: 1.year.ago.at_end_of_year)
    page.fill_in email_text, with: user.email
    page.fill_in password_text, with: "password"
    click_button sign_in_button
    page.should have_title(sign_in_title)
    page.should have_selector("div.alert-danger", text: I18n.t("session.subscription_expired"))
    expect(Login.count).to eq(1)
    expect(user.logins.where(email: nil, error: "subscription_expired", ip: ip, roles: nil).count).to eq(1)
  end

  it "recording the user's current role" do
    page.fill_in email_text, with: user.email
    page.fill_in password_text, with: password
    click_button sign_in_button
    visit "/sign_out"
    user.roles = admin_role
    user.save
    page.fill_in email_text, with: user.email
    page.fill_in password_text, with: password
    click_button sign_in_button
    visit "/sign_out"
    page.fill_in email_text, with: user.email
    page.fill_in password_text, with: password
    click_button sign_in_button
    visit "/sign_out"
    user.roles = non_admin_roles
    user.save
    page.fill_in email_text, with: user.email
    page.fill_in password_text, with: password
    click_button sign_in_button
    expect(Login.count).to eq(4)
    expect(user.logins.count).to eq(4)
    expect(user.logins.where(error: nil, roles: nil, ip: ip).count).to eq(1)
    expect(user.logins.where(error: nil, roles: admin_role, ip: ip).count).to eq(2)
    expect(user.logins.where(error: nil, roles: non_admin_roles, ip: ip).count).to eq(1)
  end
end
