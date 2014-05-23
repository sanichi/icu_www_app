require 'spec_helper'

describe "Authorization for bad logins" do
  let(:non_admin_roles) { User::ROLES.reject{ |role| role == "admin" } }
  let(:success)         { "div.alert-success" }
  let(:failure)         { "div.alert-danger" }
  let(:unauthorized)    { I18n.t("errors.alerts.unauthorized") }
  let(:signed_in_as)    { I18n.t("session.signed_in_as") }

  it "admin users can view the list" do
    logout
    login "admin"
    expect(page).to have_css(success, text: signed_in_as)
    visit admin_bad_logins_path
    expect(page).to_not have_css(failure)
  end

  it "non-admin users cannot view the list" do
    non_admin_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      visit admin_bad_logins_path
      expect(page).to have_css(failure, text: unauthorized)
    end
  end

  it "guests cannot view the logins list" do
    logout
    visit admin_bad_logins_path
    expect(page).to have_css(failure, text: unauthorized)
  end
end

describe "Listing bad logins" do
  before(:each) do
    visit "/sign_in"
    fill_in I18n.t("email"), with: email
    fill_in I18n.t("user.password"), with: password
    click_button I18n.t("session.sign_in")
    login("admin")
    visit admin_bad_logins_path
  end

  let(:email)    { "baddy@hacker.net" }
  let(:password) { "password" }
  let(:ip)       { "127.0.0.1" }

  def xpath(text)
    %Q{//table[@id="results"]/tbody/tr/td[.="#{text}"]}
  end

  it "shows user, encryted password and IP" do
    expect(page).to have_xpath(xpath(email), count: 1)
    expect(page).to have_xpath(xpath(Digest::MD5.hexdigest(password)), count: 1)
    expect(page).to have_xpath(xpath(ip), count: 1)
  end
end
