require 'spec_helper'

feature "Logins" do
  given(:non_admin_roles) { User::ROLES.reject{ |role| role == "admin" } }
  
  scenario "non-admin users have no access to the logins list" do
    non_admin_roles.each do |role|
      user = login(role)
      expect(page).to have_css("div.alert-success", text: "#{I18n.t("session.signed_in_as")} #{user.email}")
      visit admin_logins_path
      expect(page).to have_css("div.alert-danger", text: I18n.t("user.unauthorized"))
    end
  end

  scenario "guests have no access to the logins list" do
    logout
    visit admin_logins_path
    expect(page).to have_css("div.alert-danger", text: I18n.t("user.unauthorized"))
  end

  scenario "admin users have access to the logins list" do
    logout
    user = login("admin")
    expect(page).to have_css("div.alert-success", text: "#{I18n.t("session.signed_in_as")} #{user.email}")
    visit admin_logins_path
    expect(page).not_to have_css("div.alert-danger")
  end
end
