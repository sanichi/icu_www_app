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

feature "Editing users" do
  given!(:user)        { FactoryGirl.create(:user) }
  given(:success)      { "div.alert-success" }
  given(:failure)      { "div.help-block" }
  given(:signed_in_as) { I18n.t("session.signed_in_as") }
  given(:updated)      { "User was successfully updated" }

  scenario "change a user's password" do
    old_encrypted_password = user.encrypted_password
    login("admin")
    visit admin_users_path
    click_link user.email
    click_link "Edit"

    new_password = "blah"
    page.fill_in "Password", with: new_password
    click_button "Save"
    expect(page).to have_css(failure, text: "password minimum length is 6")
    user.reload
    expect(user.encrypted_password).to eq(old_encrypted_password)

    new_password = "blahblah"
    page.fill_in "Password", with: new_password
    click_button "Save"
    expect(page).to have_css(failure, text: "password should contain at least 1 digit")
    user.reload
    expect(user.encrypted_password).to eq(old_encrypted_password)

    new_password = "blah123"
    page.fill_in "Password", with: new_password
    click_button "Save"
    expect(page).to have_css(success, text: updated)
    user.reload
    expect(user.encrypted_password).not_to eq(old_encrypted_password)

    login(user, new_password)
    expect(page).to have_css(success, text: "#{signed_in_as} #{user.email}")
  end

  scenario "change a user's status" do
    login("admin")
    visit admin_users_path
    click_link user.email
    click_link "Edit"

    new_status = ""
    page.fill_in "Status", with: new_status
    click_button "Save"
    expect(page).to have_css(failure, text: "can't be blank")
    user.reload
    expect(user.status).not_to eq(new_status)

    new_status = "banned for being an asshole"
    page.fill_in "Status", with: new_status
    click_button "Save"
    expect(page).to have_css(success, text: updated)
    user.reload
    expect(user.status).to eq(new_status)
  end
end
