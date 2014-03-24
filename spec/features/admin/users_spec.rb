require 'spec_helper'

feature "Authorization for users" do
  given(:ok_roles)        { %w[admin] }
  given(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) } }
  given(:user)            { create(:user) }
  given(:paths)           { [admin_users_path, admin_user_path(user), edit_admin_user_path(user), new_admin_user_path(player_id: user.player.id), login_admin_user_path(user)] }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:unauthorized)    { I18n.t("errors.alerts.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }

  scenario "some roles can manage users" do
    ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      paths.each do |path|
        visit path
        expect(page).to_not have_css(failure)
      end
    end
  end

  scenario "non-admin roles cannot access users" do
    not_ok_roles.push("guest").each do |role|
      if role == "guest"
        logout
      else
        login role
        expect(page).to have_css(success, text: signed_in_as)
      end
      paths.each do |path|
        visit path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end
end

feature "Creating users" do
  given(:player)       { create(:player) }
  given(:user)         { create(:user) }
  given(:player_path)  { admin_player_path(player) }
  given(:new_user)     { "New user" }
  given(:email)        { "joe@example.com" }
  given(:password)     { "new passw0rd" }
  given(:expires_on)   { Date.today.years_since(1).end_of_year }
  given(:role)         { "translator" }
  given(:success)      { "div.alert-success" }
  given(:failure)      { "div.help-block" }
  given(:created)      { "User was successfully created" }
  given(:signed_in_as) { I18n.t("session.signed_in_as") }

  scenario "add a user to a player" do
    login "admin"
    visit player_path

    click_link new_user
    fill_in "Email", with: user.email
    fill_in "Password", with: password
    fill_in "Expires on", with: expires_on
    select I18n.t("user.role.#{role}"), from: "Roles"

    click_button "Save"
    expect(page).to have_css(failure, text: "taken")

    fill_in "Email", with: email
    click_button "Save"
    expect(page).to have_css(success, text: created)

    new_user = User.find_by(email: email)
    expect(new_user.roles).to eq role
    expect(new_user.player_id).to eq player.id
    expect(new_user.status).to eq User::OK
    expect(new_user.verified?).to be_true

    click_link I18n.t("session.sign_out")
    fill_in I18n.t("email"), with: email
    fill_in I18n.t("user.password"), with: password
    click_button I18n.t("session.sign_in")
    expect(page).to have_css(success, text: signed_in_as)
  end
end

feature "Editing users" do
  given!(:user)        { create(:user) }
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
    fill_in "Password", with: new_password
    click_button "Save"
    expect(page).to have_css(failure, text: min_length)
    user.reload
    expect(user.encrypted_password).to eq(old_encrypted_password)

    new_password = "blahblah"
    fill_in "Password", with: new_password
    click_button "Save"
    expect(page).to have_css(failure, text: no_digits)
    user.reload
    expect(user.encrypted_password).to eq(old_encrypted_password)

    new_password = "blah1234"
    fill_in "Password", with: new_password
    click_button "Save"
    expect(page).to have_css(success, text: updated)
    user.reload
    expect(user.encrypted_password).to_not eq(old_encrypted_password)

    login user, password: new_password
    expect(page).to have_css(success, text: "#{signed_in_as} #{user.email}")
  end

  scenario "change a user's roles" do
    expect(user.roles).to be_nil

    login "admin"
    visit edit_path

    select "Editor", from: "Roles"
    click_button "Save"
    expect(page).to have_css(success, text: updated)
    user.reload
    expect(user.roles).to eq("editor")

    click_link "Edit"
    unselect "Editor", from: "Roles"
    select "Translator", from: "Roles"
    select "Treasurer", from: "Roles"
    click_button "Save"
    expect(page).to have_css(success, text: updated)
    user.reload
    expect(user.roles).to eq("translator treasurer")

    click_link "Edit"
    unselect "Translator", from: "Roles"
    unselect "Treasurer", from: "Roles"
    click_button "Save"
    expect(page).to have_css(success, text: updated)
    user.reload
    expect(user.roles).to be_nil
  end

  scenario "the last admin role" do
    admin = login "admin"
    visit edit_admin_user_path(admin)

    unselect "Administrator", from: "Roles"
    click_button "Save"
    expect(page).to have_css(failure)
  end

  scenario "change a user's status" do
    login"admin"
    visit edit_path

    new_status = ""
    fill_in "Status", with: new_status
    click_button "Save"
    expect(page).to have_css(failure, text: "can't be blank")
    user.reload
    expect(user.status).to_not eq(new_status)

    new_status = "banned for being an asshole"
    fill_in "Status", with: new_status
    click_button "Save"
    expect(page).to have_css(success, text: updated)
    user.reload
    expect(user.status).to eq(new_status)
  end

  scenario "verifying a user" do
    expect(user.verified_at.to_i).to_not be_within(1).of(Time.now.to_i)

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

  scenario "changing the expiry date" do
    expiry = user.expires_on

    login "admin"
    visit edit_path
    expect(page).to have_field("Expires on")

    fill_in "Expires on", with: Date.new(expiry.year + 1, expiry.month, expiry.day).to_s
    click_button "Save"
    expect(page).to have_css(success, text: updated)

    user.reload
    expect(user.expires_on).to eq expiry.years_since(1)
  end
end

feature "Search users" do
  before(:each) do
    create(:user)
    create(:user, roles: "editor")
    create(:user, roles: "translator treasurer")
    create(:user, roles: "translator")
    create(:user, verified_at: nil)
    create(:user, expires_on: Date.today.years_ago(2).end_of_year)
    create(:user, expires_on: Date.today.years_ago(3).end_of_year)
    create(:user, expires_on: Date.today.years_since(10).end_of_year)
    create(:user, status: "Plonker")
    create(:user, status: "Dickhead")
    @admin = login "admin"
    @total = User.count
    @xpath = "//table[@id='results']/tbody/tr"
    visit admin_users_path
  end

  scenario "all users" do
    expect(page).to have_xpath(@xpath, count: @total)
  end

  scenario "email" do
    fill_in "Email", with: @admin.email
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
  end

  scenario "expired" do
    select "Active", from: "Expiry"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: @total - 2)
    select "Expired", from: "Expiry"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 2)
    select "Extended", from: "Expiry"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
  end

  scenario "status" do
    select "OK", from: "Status"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: @total - 2)
    select "Not OK", from: "Status"
    click_button "Search"
    expect(page).to have_xpath(@xpath, 2)
  end

  scenario "verified" do
    select "Verified", from: "Verified"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: @total - 1)
    select "Unverified", from: "Verified"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
  end

  scenario "roles" do
    select "Some Role", from: "Role"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: @total - 7)
    select "No Role", from: "Role"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 7)
    select "Translator", from: "Role"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 2)
    select "Administrator", from: "Role"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
  end
end

feature "View users" do
  before(:each) do
    create(:user)
    @admin = login "admin"
    @xpath = "//table[@id='results']/tbody/tr"
    visit admin_users_path
  end

  scenario "clicking the 'Last' button" do
    expect(page).to have_xpath(@xpath, count: 2)
    select "Admin", from: "Role"
    click_button "Search"
    expect(page).to have_xpath(@xpath, count: 1)
    click_link @admin.email
    click_link "Last"
    expect(page).to have_xpath(@xpath, count: 1)
  end
end

feature "Delete users" do
  given(:success) { "div.alert-success" }
  given(:failure) { "div.alert-danger" }
  given(:deleted) { "successfully deleted" }
  given(:logins)  { "login" }
  given(:roles)   { "role" }

  [true, false].each do |js|
    scenario "can if they have no logins or roles (with#{js ? '' : 'out'} js)", js: js do
      user = create(:user)
      expect(Login.where(user_id: user.id).count).to eq 0
      login "admin"
      visit admin_user_path(user)
      click_link "Delete"
      confirm_dialog if js
      expect(page).to have_css(success, text: deleted)
      expect(User.where(id: user.id).count).to eq 0
    end
  end

  scenario "can't if they have a login history" do
    user = create(:user)
    number = 5
    number.times { create(:login, user: user) }
    expect(Login.where(user_id: user.id).count).to eq number
    login "admin"
    visit admin_user_path(user)
    click_link "Delete"
    expect(page).to have_css(failure, text: logins)
    expect(User.where(id: user.id).count).to eq 1
    expect(Login.where(user_id: user.id).count).to eq number
  end

  scenario "can't if they have any roles" do
    user = create(:user, roles: "translator")
    login "admin"
    visit admin_user_path(user)
    click_link "Delete"
    expect(page).to have_css(failure, text: roles)
    expect(User.where(id: user.id).count).to eq 1
  end
end

feature "Login as another user" do
  given(:success) { "div.alert-success" }
  given(:message) { I18n.t("session.signed_in_as") }
  given!(:user)   { create(:user) }

  scenario "click the login button" do
    login "admin"
    original_count = Login.count
    visit admin_user_path(user)
    click_link "Login"
    expect(page).to have_css(success, text: "#{message} #{user.email}")
    click_link I18n.t("user.account")
    expect(page).to have_content(user.email)
    expect(Login.count).to eq(original_count)
  end
end
