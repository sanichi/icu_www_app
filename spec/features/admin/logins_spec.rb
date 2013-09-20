require 'spec_helper'

feature "Authorization for logins" do
  given(:non_admin_roles) { User::ROLES.reject{ |role| role == "admin" } }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:unauthorized)    { I18n.t("user.unauthorized") }
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
