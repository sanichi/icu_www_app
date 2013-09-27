require 'spec_helper'

feature "Authorization for users" do
  given(:non_admin_roles) { User::ROLES.reject{ |role| role == "admin" } }
  given(:user)            { FactoryGirl.create(:user) }
  given(:paths)           { [admin_users_path, admin_user_path(user), edit_admin_user_path(user), login_admin_user_path(user)] }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:unauthorized)    { I18n.t("errors.messages.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }

  scenario "the admin role can manage users" do
    login "admin"
    expect(page).to have_css(success, text: signed_in_as)
    paths.each do |path|
      visit path
      expect(page).not_to have_css(failure)
    end
  end

  scenario "non-admin roles cannot access users" do
    non_admin_roles.each do |role|
      login role
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
  given(:edit_path)    { edit_admin_user_path(user) }
  given(:success)      { "div.alert-success" }
  given(:failure)      { "div.help-block" }
  given(:signed_in_as) { I18n.t("session.signed_in_as") }
  given(:updated)      { "User was successfully updated" }
  given(:min_length)   { I18n.t("errors.attributes.password.length", minimum: User::MINIMUM_PASSWORD_LENGTH) }
  given(:no_digits)    { I18n.t("errors.attributes.password.digits") }

  scenario "change a user's password" do
    old_encrypted_password = user.encrypted_password
    login "admin"
    visit edit_path

    new_password = "blah"
    page.fill_in "Password", with: new_password
    click_button "Save"
    expect(page).to have_css(failure, text: min_length)
    user.reload
    expect(user.encrypted_password).to eq(old_encrypted_password)

    new_password = "blahblah"
    page.fill_in "Password", with: new_password
    click_button "Save"
    expect(page).to have_css(failure, text: no_digits)
    user.reload
    expect(user.encrypted_password).to eq(old_encrypted_password)

    new_password = "blah1234"
    page.fill_in "Password", with: new_password
    click_button "Save"
    expect(page).to have_css(success, text: updated)
    user.reload
    expect(user.encrypted_password).not_to eq(old_encrypted_password)

    login user, password: new_password
    expect(page).to have_css(success, text: "#{signed_in_as} #{user.email}")
  end

  scenario "change a user's roles" do
    expect(user.roles).to be_nil

    login "admin"
    visit edit_path

    page.select "Editor", from: "Roles"
    click_button "Save"
    expect(page).to have_css(success, text: updated)
    user.reload
    expect(user.roles).to eq("editor")

    click_link "Edit"
    page.unselect "Editor", from: "Roles"
    page.select "Translator", from: "Roles"
    page.select "Treasurer", from: "Roles"
    click_button "Save"
    expect(page).to have_css(success, text: updated)
    user.reload
    expect(user.roles).to eq("translator treasurer")

    click_link "Edit"
    page.unselect "Translator", from: "Roles"
    page.unselect "Treasurer", from: "Roles"
    click_button "Save"
    expect(page).to have_css(success, text: updated)
    user.reload
    expect(user.roles).to be_nil
  end

  scenario "the last admin role" do
    admin = login "admin"
    visit edit_admin_user_path(admin)

    page.unselect "Administrator", from: "Roles"
    click_button "Save"
    expect(page).to have_css(failure)
  end

  scenario "change a user's status" do
    login"admin"
    visit edit_path

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

  scenario "verifying a user" do
    expect(user.verified_at.to_i).not_to be_within(1).of(Time.now.to_i)

    login "admin"
    visit edit_path
    expect(page).to have_no_field("Verify")

    user.verified_at = nil
    user.save
    visit edit_path
    expect(page).to have_field("Verify")

    check "Verify"
    click_button "Save"
    expect(page).to have_css(success, text: updated)
    user.reload
    expect(user).to be_verified
    expect(user.verified_at.to_i).to be_within(1).of(Time.now.to_i)

    visit edit_path
    expect(page).to have_no_field("Verify")
  end
end

feature "Search users" do
  before(:each) do
    FactoryGirl.create(:user)
    FactoryGirl.create(:user, roles: "editor")
    FactoryGirl.create(:user, roles: "translator treasurer")
    FactoryGirl.create(:user, roles: "translator")
    FactoryGirl.create(:user, verified_at: nil)
    FactoryGirl.create(:user, expires_on: Date.today.years_ago(2).end_of_year)
    FactoryGirl.create(:user, expires_on: Date.today.years_ago(3).end_of_year)
    FactoryGirl.create(:user, expires_on: Date.today.years_since(10).end_of_year)
    FactoryGirl.create(:user, status: "Plonker")
    FactoryGirl.create(:user, status: "Dickhead")
    @admin = login "admin"
    @total = User.count
    @xpath = "//table[@id='results']/tbody/tr"
    visit admin_users_path
  end

  scenario "all users" do
    expect(page).to have_xpath(@xpath, count: @total)
  end

  scenario "email" do
    page.fill_in "Email", with: @admin.email
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
  end

  scenario "expired" do
    page.select "Active", from: "Expiry"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: @total - 2)
    page.select "Expired", from: "Expiry"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 2)
    page.select "Extended", from: "Expiry"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
  end

  scenario "status" do
    page.select "OK", from: "Status"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: @total - 2)
    page.select "Not OK", from: "Status"
    click_button "Search"
    expect(page).to have_xpath(@xpath, 2)
  end

  scenario "verified" do
    page.select "Verified", from: "Verified"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: @total - 1)
    page.select "Unverified", from: "Verified"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
  end

  scenario "roles" do
    page.select "Some Role", from: "Role"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: @total - 7)
    page.select "No Role", from: "Role"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 7)
    page.select "Translator", from: "Role"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 2)
    page.select "Administrator", from: "Role"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
  end
end

feature "View users" do
  before(:each) do
    FactoryGirl.create(:user)
    @admin = login "admin"
    @xpath = "//table[@id='results']/tbody/tr"
    visit admin_users_path
  end

  scenario "clicking the 'Last' button" do
    expect(page).to have_xpath(@xpath, count: 2)
    page.select "Admin", from: "Role"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    page.click_link @admin.email
    click_link "Last"
    expect(page).to have_xpath(@xpath, count: 1)
  end
end

feature "Delete users" do
  given(:success) { "div.alert-success" }
  given(:deleted) { "successfully deleted" }

  scenario "login history is retained but nullified", js: true do
    user = FactoryGirl.create(:user)
    number = 5
    number.times { FactoryGirl.create(:login, user: user) }
    expect(Login.where(user_id: user.id).count).to eq(number)
    expect(Login.where(email: user.email).count).to eq(number)
    login "admin"
    visit admin_user_path(user)
    click_link "Delete"
    page.driver.browser.switch_to.alert.accept
    expect(page).to have_css(success, text: deleted)
    expect(Login.where(user_id: user.id).count).to eq(0)
    expect(Login.where(email: user.email).count).to eq(number)
  end
end

feature "Login as another user" do
  given(:success) { "div.alert-success" }
  given(:message) { I18n.t("session.signed_in_as") }
  given!(:user)   { FactoryGirl.create(:user) }

  scenario "click the login button" do
    login "admin"
    original_count = Login.count
    visit admin_user_path(user)
    click_link "Login"
    expect(page).to have_css(success, text: "#{message} #{user.email}")
    click_link I18n.t("user.preferences")
    expect(page).to have_content(user.email)
    expect(Login.count).to eq(original_count)
  end
end
