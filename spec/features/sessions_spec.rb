require 'rails_helper'

describe "Sessions" do
  include_context "features"

  let(:disabled)         { I18n.t("session.account_disabled") }
  let(:expired)          { I18n.t("session.subscription_expired") }
  let(:icu)              { I18n.t("icu.icu") }
  let(:invalid_email)    { I18n.t("session.invalid_email") }
  let(:invalid_password) { I18n.t("session.invalid_password") }
  let(:password)         { I18n.t("user.password") }
  let(:sign_in_button)   { I18n.t("session.sign_in") }
  let(:sign_in_title)    { I18n.t("session.sign_in") }
  let(:sign_out_button)  { I18n.t("session.sign_out") }
  let(:signed_in_as)     { I18n.t("session.signed_in_as") }
  let(:unverified)       { I18n.t("session.unverified_email") }

  context "signing in" do
    let(:good_password) { "password" }
    let(:bad_password)  { "drowssap" }
    let(:ip)            { "127.0.0.1" }
    let(:level1)        { "admin" }
    let(:level2)        { User::ROLES.reject{ |r| r == level1 }.sample(2).sort.join(" ") }
    let(:user)          { create(:user) }

    before(:each) do
      visit sign_in_path
    end

    it "arriving at the sign in page" do
      expect(page).to have_title(sign_in_title)
      expect(page).to have_xpath("//form//input[@name='email']")
      expect(page).to have_xpath("//form//input[@name='password']")
    end

    it "signing in and signing out" do
      fill_in email, with: user.email
      fill_in password, with: good_password
      click_button sign_in_button
      expect(page).to have_title(icu)
      expect(page).to have_css(success, text: signed_in_as)
      expect(Login.count).to eq 1
      expect(user.logins.where(user_id: user.id, ip: ip, roles: nil, error: nil).count).to eq(1)
      click_link sign_out_button
      click_link sign_in_button
      expect(page).to have_title(sign_in_title)
      expect(page).to have_xpath("//form//input[@name='email']")
    end

    it "entering an invalid email" do
      bad_email = "bad." + user.email
      fill_in email, with: bad_email
      fill_in password, with: good_password
      click_button sign_in_button
      expect(page).to have_title(sign_in_title)
      expect(page).to have_css(failure, text: invalid_email)
      expect(Login.count).to eq 0
    end

    it "entering an invalid password" do
      fill_in email, with: user.email
      fill_in password, with: bad_password
      click_button sign_in_button
      expect(page).to have_title(sign_in_title)
      expect(page).to have_css(failure, text: invalid_password)
      expect(Login.count).to eq 1
      expect(user.logins.where(user_id: user.id, ip: ip, roles: nil, error: "invalid_password").count).to eq(1)
    end

    it "the user's subscription has expired" do
      user = create(:user, expires_on: 1.year.ago.at_end_of_year)
      fill_in email, with: user.email
      fill_in password, with: good_password
      click_button sign_in_button
      expect(page).to have_title(sign_in_title)
      expect(page).to have_selector(failure, text: expired)
      expect(Login.count).to eq 1
      expect(user.logins.where(user_id: user.id, ip: ip, roles: nil, error: "subscription_expired").count).to eq(1)
    end

    it "the user is waiting for verification" do
      user = create(:user, verified_at: nil)
      fill_in email, with: user.email
      fill_in password, with: good_password
      click_button sign_in_button
      expect(page).to have_title(sign_in_title)
      expect(page).to have_selector(failure, text: unverified)
      expect(Login.count).to eq 1
      expect(user.logins.where(user_id: user.id, ip: ip, roles: nil, error: "unverified_email").count).to eq(1)
    end

    it "the user has a bad status" do
      user = create(:user, status: "Banned for being a complete idiot")
      fill_in email, with: user.email
      fill_in password, with: good_password
      click_button sign_in_button
      expect(page).to have_title(sign_in_title)
      expect(page).to have_selector(failure, text: disabled)
      expect(Login.count).to eq 1
      expect(user.logins.where(user_id: user.id, ip: ip, roles: nil, error: "account_disabled").count).to eq(1)
    end

    it "recording the user's current role" do
      create(:user, roles: level1) # so there is a last admin
      fill_in email, with: user.email
      fill_in password, with: good_password
      click_button sign_in_button
      click_link sign_out_button
      user.roles = level1
      user.save
      click_link sign_in_button
      fill_in email, with: user.email
      fill_in password, with: good_password
      click_button sign_in_button
      click_link sign_out_button
      click_link sign_in_button
      fill_in email, with: user.email
      fill_in password, with: good_password
      click_button sign_in_button
      click_link sign_out_button
      user.roles = level2
      user.save
      click_link sign_in_button
      fill_in email, with: user.email
      fill_in password, with: good_password
      click_button sign_in_button
      expect(Login.count).to eq(4)
      expect(user.logins.count).to eq(4)
      expect(user.logins.where(roles: nil, ip: ip).count).to eq(1)
      expect(user.logins.where(roles: level1, ip: ip).count).to eq(2)
      expect(user.logins.where(roles: level2, ip: ip).count).to eq(1)
    end
  end

  context "redirecting to the last page before sign in" do
    it "clubs#index" do
      visit clubs_path
      expect(page).to have_title(I18n.t("club.clubs"))
      login
      expect(page).to have_css(success, text: signed_in_as)
      expect(page).to have_title(I18n.t("club.clubs"))
    end

    it "help#index" do
      visit help_index_path
      expect(page).to have_title(I18n.t("help.help"))
      login
      expect(page).to have_css(success, text: signed_in_as)
      expect(page).to have_title(I18n.t("help.help"))
    end

    it "icu#constitution" do
      visit icu_constitution_path
      expect(page).to have_title(I18n.t("icu.constitution"))
      login
      expect(page).to have_css(success, text: signed_in_as)
      expect(page).to have_title(I18n.t("icu.constitution"))
    end

    it "pages#links" do
      visit links_path
      expect(page).to have_title(I18n.t("links.links"))
      login
      expect(page).to have_css(success, text: signed_in_as)
      expect(page).to have_title(I18n.t("links.links"))
    end

    it "payments#shop" do
      visit shop_path
      expect(page).to have_title(I18n.t("shop.shop"))
      login
      expect(page).to have_css(success, text: signed_in_as)
      expect(page).to have_title(I18n.t("shop.shop"))
    end
  end
end
