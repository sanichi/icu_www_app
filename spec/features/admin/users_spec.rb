require 'rails_helper'

describe User do
  include_context "features"

  let(:administrator)  { I18n.t("user.role.admin") }
  let(:editor)         { I18n.t("user.role.editor") }
  let(:expires)        { I18n.t("user.expires") }
  let(:password)       { I18n.t("user.password") }
  let(:role)           { I18n.t("user.role.role") }
  let(:roles)          { I18n.t("user.role.roles") }
  let(:sign_in)        { I18n.t("session.sign_in") }
  let(:sign_out)       { I18n.t("session.sign_out") }
  let(:signed_in_as)   { I18n.t("session.signed_in_as") }
  let(:status)         { I18n.t("user.status") }
  let(:translator)     { I18n.t("user.role.translator") }
  let(:treasurer)      { I18n.t("user.role.treasurer") }
  let(:user_account)   { I18n.t("user.account") }
  let(:verified)       { I18n.t("user.verified") }
  let(:verify)         { I18n.t("user.verify") }

  context "authorization" do
    let(:level1) { %w[admin] }
    let(:level2) { User::ROLES.reject { |role| level1.include?(role) }.append("guest") }
    let(:paths)  { [admin_users_path, admin_user_path(user), edit_admin_user_path(user), new_admin_user_path(player_id: user.player.id), login_admin_user_path(user)] }
    let(:user)   { create(:user) }

    it "level 1 can manage users" do
      level1.each do |role|
        login role
        paths.each do |path|
          visit path
          expect(page).to_not have_css(failure)
        end
      end
    end

    it "level 2 cannot access users" do
      level2.each do |role|
        login role
        paths.each do |path|
          visit path
          expect(page).to have_css(failure, text: unauthorized)
        end
      end
    end
  end

  context "create" do
    let(:player)       { create(:player) }
    let(:user)         { create(:user) }
    let(:player_path)  { admin_player_path(player) }
    let(:new_user)     { "New user" }
    let(:my_email)     { "joe@example.com" }
    let(:my_password)  { "new passw0rd" }
    let(:expires_on)   { Date.today.years_since(1).end_of_year }
    let(:role)         { "translator" }

    it "add a user to a player" do
      login "admin"
      visit player_path

      click_link new_user
      fill_in email, with: user.email
      fill_in password, with: my_password
      fill_in expires, with: expires_on
      select I18n.t("user.role.#{role}"), from: roles

      click_button save
      expect(page).to have_css(field_error, text: "taken")

      fill_in email, with: my_email
      click_button save
      expect(page).to have_css(success, text: created)

      new_user = User.find_by(email: my_email)
      expect(new_user.roles).to eq role
      expect(new_user.player_id).to eq player.id
      expect(new_user.status).to eq User::OK
      expect(new_user.verified?).to be true

      click_link sign_out
      click_link sign_in
      fill_in email, with: my_email
      fill_in password, with: my_password
      click_button sign_in
      expect(page).to have_css(success, text: signed_in_as)
    end
  end

  context "edit" do
    let!(:user)        { create(:user) }
    let(:edit_path)    { edit_admin_user_path(user) }
    let(:min_length)   { I18n.t("errors.attributes.password.length", minimum: User::MINIMUM_PASSWORD_LENGTH) }
    let(:no_digits)    { I18n.t("errors.attributes.password.digits") }

    it "change a user's password" do
      old_encrypted_password = user.encrypted_password
      login "admin"
      visit edit_path

      new_password = "blah"
      fill_in password, with: new_password
      click_button save
      expect(page).to have_css(field_error, text: min_length)
      user.reload
      expect(user.encrypted_password).to eq(old_encrypted_password)

      new_password = "blahblah"
      fill_in password, with: new_password
      click_button save
      expect(page).to have_css(field_error, text: no_digits)
      user.reload
      expect(user.encrypted_password).to eq(old_encrypted_password)

      new_password = "blah1234"
      fill_in password, with: new_password
      click_button save
      expect(page).to have_css(success, text: updated)
      user.reload
      expect(user.encrypted_password).to_not eq(old_encrypted_password)

      login user, password: new_password
      expect(page).to have_css(success, text: "#{signed_in_as} #{user.email}")
    end

    it "change a user's roles" do
      expect(user.roles).to be_nil

      login "admin"
      visit edit_path

      select editor, from: roles
      click_button save
      expect(page).to have_css(success, text: updated)
      user.reload
      expect(user.roles).to eq("editor")

      click_link edit
      unselect editor, from: roles
      select translator, from: roles
      select treasurer, from: roles
      click_button save
      expect(page).to have_css(success, text: updated)
      user.reload
      expect(user.roles).to eq("translator treasurer")

      click_link edit
      unselect translator, from: roles
      unselect treasurer, from: roles
      click_button save
      expect(page).to have_css(success, text: updated)
      user.reload
      expect(user.roles).to be_nil
    end

    it "the last admin role" do
      admin = login "admin"
      visit edit_admin_user_path(admin)

      unselect administrator, from: roles
      click_button save
      expect(page).to have_css(field_error)
    end

    it "change a user's status" do
      login"admin"
      visit edit_path

      new_status = ""
      fill_in status, with: new_status
      click_button save
      expect(page).to have_css(field_error, text: "can't be blank")
      user.reload
      expect(user.status).to_not eq(new_status)

      new_status = "banned for being an asshole"
      fill_in status, with: new_status
      click_button save
      expect(page).to have_css(success, text: updated)
      user.reload
      expect(user.status).to eq(new_status)
    end

    it "verifying a user" do
      expect(user.verified_at.to_i).to_not be_within(1).of(Time.now.to_i)

      login "admin"
      visit edit_path
      expect(page).to have_no_field(verify)

      user.verified_at = nil
      user.save
      visit edit_path
      expect(page).to have_field(verify)

      check verify
      click_button save
      expect(page).to have_css(success, text: updated)
      user.reload
      expect(user).to be_verified
      expect(user.verified_at.to_i).to be_within(1).of(Time.now.to_i)

      visit edit_path
      expect(page).to have_no_field(verify)
    end

    it "changing the expiry date" do
      expiry = user.expires_on

      login "admin"
      visit edit_path

      fill_in expires, with: Date.new(expiry.year + 1, expiry.month, expiry.day).to_s
      click_button save
      expect(page).to have_css(success, text: updated)

      user.reload
      expect(user.expires_on).to eq expiry.years_since(1)
    end
  end

  context "search" do
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

    it "all users" do
      expect(page).to have_xpath(@xpath, count: @total)
    end

    it "email" do
      fill_in email, with: @admin.email
      click_button search
      expect(page).to have_xpath(@xpath, count: 1)
    end

    it "expired" do
      select "Active", from: expires
      click_button search
      expect(page).to have_xpath(@xpath, count: @total - 2)
      select "Expired", from: expires
      click_button search
      expect(page).to have_xpath(@xpath, count: 2)
      select "Extended", from: expires
      click_button search
      expect(page).to have_xpath(@xpath, count: 1)
    end

    it "status" do
      select "OK", from: status
      click_button search
      expect(page).to have_xpath(@xpath, count: @total - 2)
      select "Not OK", from: status
      click_button search
      expect(page).to have_xpath(@xpath, 2)
    end

    it "verified" do
      select "Verified", from: verified
      click_button search
      expect(page).to have_xpath(@xpath, count: @total - 1)
      select "Unverified", from: verified
      click_button search
      expect(page).to have_xpath(@xpath, count: 1)
    end

    it "roles" do
      select "Some Role", from: role
      click_button search
      expect(page).to have_xpath(@xpath, count: @total - 7)
      select "No Role", from: role
      click_button search
      expect(page).to have_xpath(@xpath, count: 7)
      select translator, from: role
      click_button search
      expect(page).to have_xpath(@xpath, count: 2)
      select administrator, from: role
      click_button search
      expect(page).to have_xpath(@xpath, count: 1)
    end
  end

  context "view" do
    before(:each) do
      create(:user)
      @admin = login "admin"
      @xpath = "//table[@id='results']/tbody/tr"
      visit admin_users_path
    end

    it "clicking the 'Last' button" do
      expect(page).to have_xpath(@xpath, count: 2)
      select "Admin", from: role
      click_button search
      expect(page).to have_xpath(@xpath, count: 1)
      click_link @admin.email
      click_link "Last"
      expect(page).to have_xpath(@xpath, count: 1)
    end
  end

  context "delete" do
    let(:logins) { "login" }
    let(:roles)  { "role" }

    [true, false].each do |js|
      it "can if they have no logins or roles (with#{js ? '' : 'out'} js)", js: js do
        user = create(:user)
        expect(Login.where(user_id: user.id).count).to eq 0
        login "admin"
        visit admin_user_path(user)
        click_link delete
        confirm_dialog if js
        expect(page).to have_css(success, text: deleted)
        expect(User.where(id: user.id).count).to eq 0
      end
    end

    it "can't if they have a login history" do
      user = create(:user)
      number = 5
      number.times { create(:login, user: user) }
      expect(Login.where(user_id: user.id).count).to eq number
      login "admin"
      visit admin_user_path(user)
      click_link delete
      expect(page).to have_css(failure, text: logins)
      expect(User.where(id: user.id).count).to eq 1
      expect(Login.where(user_id: user.id).count).to eq number
    end

    it "can't if they have any roles" do
      user = create(:user, roles: "translator")
      login "admin"
      visit admin_user_path(user)
      click_link delete
      expect(page).to have_css(failure, text: roles)
      expect(User.where(id: user.id).count).to eq 1
    end
  end

  context "login as another user" do
    let!(:user) { create(:user) }

    it "click the login button" do
      login "admin"
      original_count = Login.count
      visit admin_user_path(user)
      click_link "Login"
      expect(page).to have_css(success, text: "#{signed_in_as} #{user.email}")
      click_link user_account
      expect(page).to have_content(user.email)
      expect(Login.count).to eq(original_count)
    end
  end
end
