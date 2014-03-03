require 'spec_helper'

feature "Authorization for pages" do
  given(:non_admin_roles) { User::ROLES.reject { |role| role == "admin" } }
  given(:paths)           { [admin_system_info_path, admin_test_email_path] }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:unauthorized)    { I18n.t("errors.messages.unauthorized") }

  scenario "admin role" do
    login "admin"
    paths.each do |path|
      visit path
      expect(page).to_not have_css(failure)
    end
  end

  scenario "other roles and guests" do
    non_admin_roles.push("guest").each do |role|
      if role == "guest"
        logout
      else
        login role
      end
      paths.each do |path|
        visit path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end
end
