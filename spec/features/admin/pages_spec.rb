require 'spec_helper'

feature "Authorization for pages" do
  given(:non_admin_roles) { User::ROLES.reject { |role| role == "admin" } }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:unauthorized)    { I18n.t("errors.messages.unauthorized") }

  scenario "admin role" do
    login "admin"
    visit admin_system_info_path
    expect(page).to_not have_css(failure)
  end

  scenario "other roles and guests" do
    non_admin_roles.push("guest").each do |role|
      if role == "guest"
        logout
      else
        login role
      end
      visit admin_system_info_path
      expect(page).to have_css(failure, text: unauthorized)
    end
  end
end
