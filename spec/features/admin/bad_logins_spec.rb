require 'spec_helper'

feature "Authorization for bad logins" do
  given(:non_admin_roles) { User::ROLES.reject{ |role| role == "admin" } }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:unauthorized)    { I18n.t("errors.messages.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }

  scenario "admin users can view the list" do
    logout
    login "admin"
    expect(page).to have_css(success, text: signed_in_as)
    visit admin_bad_logins_path
    expect(page).to_not have_css(failure)
  end

  scenario "non-admin users cannot view the list" do
    non_admin_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      visit admin_bad_logins_path
      expect(page).to have_css(failure, text: unauthorized)
    end
  end

  scenario "guests cannot view the logins list" do
    logout
    visit admin_bad_logins_path
    expect(page).to have_css(failure, text: unauthorized)
  end
end

feature "Listing bad logins" do
  before(:each) do
    visit "/sign_in"
    fill_in I18n.t("user.email"), with: email
    fill_in I18n.t("user.password"), with: password
    click_button I18n.t("session.sign_in")
    login("admin")
    visit admin_bad_logins_path
  end

  given(:email)    { "baddy@hacker.net" }
  given(:password) { "password" }
  given(:ip)       { "127.0.0.1" }

  def xpath(text)
    "//table[@id='results']/tbody/tr/td[.='#{text}']"
  end

  it "shows user, encryted password and IP" do
    expect(page).to have_xpath(xpath(email), count: 1)
    expect(page).to have_xpath(xpath(Digest::MD5.hexdigest(password)), count: 1)
    expect(page).to have_xpath(xpath(ip), count: 1)
  end
end
