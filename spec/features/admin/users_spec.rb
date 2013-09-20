require 'spec_helper'

feature "Authorization for users" do
  given(:non_admin_roles) { User::ROLES.reject{ |role| role == "admin" } }
  given(:user)            { FactoryGirl.create(:user) }
  given(:paths)           { [admin_users_path, admin_user_path(user.id), edit_admin_user_path(user.id)] }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:unauthorized)    { I18n.t("user.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }

  scenario "the admin role can manage users" do
    login("admin")
    expect(page).to have_css(success, text: signed_in_as)
    paths.each do |path|
      visit path
      expect(page).not_to have_css(failure)
    end
  end

  scenario "non-admin roles cannot access users" do
    non_admin_roles.each do |role|
      login(role)
      expect(page).to have_css(success, text: signed_in_as)
      paths.each do |path|
        visit path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end

  scenario "guests cannot access users" do
    logout
    visit admin_users_path
    paths.each do |path|
      visit path
      expect(page).to have_css(failure, text: unauthorized)
    end
  end
end
