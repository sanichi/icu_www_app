require 'spec_helper'

feature "Authorization for pages" do
  given(:non_admin_roles) { User::ROLES.reject { |role| role == "admin" } }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:unauthorized)    { I18n.t("errors.messages.unauthorized") }

  scenario "admin role" do
    login "admin"
    visit system_info_path
    expect(page).to_not have_css(failure)
  end

  scenario "other roles" do
    non_admin_roles.each do |role|
      login role
      visit system_info_path
      expect(page).to have_css(failure, text: unauthorized)
    end
  end

  scenario "guests" do
    logout
    visit system_info_path
    expect(page).to have_css(failure, text: unauthorized)
  end
end
