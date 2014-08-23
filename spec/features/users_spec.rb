require 'rails_helper'

describe User do
  include_context "features"

  let(:account)         { I18n.t("user.account") }
  let(:change_password) { I18n.t("user.change_password") }
  let(:english)         { I18n.t("user.lang.en") }
  let(:irish)           { I18n.t("user.lang.ga") }
  let(:irish_ga)        { I18n.t("user.lang.ga", locale: "ga") }
  let(:locale)          { I18n.t("user.locale") }
  let(:locale_ga)       { I18n.t("user.locale", locale: "ga") }
  let(:new_password_1)  { I18n.t("user.new_password_1") }
  let(:new_password_2)  { I18n.t("user.new_password_2") }
  let(:old_password)    { I18n.t("user.old_password") }
  let(:preferences)     { I18n.t("user.preferences") }
  let(:signed_in_as)    { I18n.t("session.signed_in_as") }
  let(:theme)           { I18n.t("user.theme") }

  context "authorization" do
    let(:paths)      { [account_path(user), preferences_path(user), edit_user_path(user)] }
    let(:other_user) { create(:user) }
    let(:user)       { create(:user) }
    let(:level1)     { ["admin", user] }
    let(:level2)     { User::ROLES.reject { |role| level1.include?(role) }.append("guest").append(other_user) }

    it "level 1 can manage user" do
      level1.each do |user|
        login user
        paths.each do |path|
          visit path
          expect(page).to_not have_css(failure)
        end
      end
    end

    it "other users cannot manage user" do
      level2.each do |user|
        login user
        paths.each do |path|
          visit path
          expect(page).to have_css(failure, unauthorized)
        end
      end
    end
  end

  context "preferences" do
    let(:user)   { create(:user) }
    let(:random) { User::THEMES.reject{ |t| t == User::DEFAULT_THEME }.sample }

    before(:each) do
      login user
      click_link user.player.name
      click_link preferences
    end

    it "change theme", js: true do
      expect(user.theme).to be_nil
      select random, from: theme
      expect(page).to have_xpath("/html/head/link[@rel='stylesheet' and starts-with(@href,'/assets/#{random.downcase}.min.css')]", visible: false)
      expect(page).to have_select(theme, selected: random)
      user.reload
      expect(user.theme).to eq(random)
    end

    it "change locale", js: true do
      expect(user.locale).to eq("en")
      select irish, from: locale
      expect(page).to have_select(locale_ga, selected: irish_ga)
      user.reload
      expect(user.locale).to eq("ga")
    end
  end

  context "change password" do
    let(:user)         { create(:user) }
    let(:fst_password) { "password" }

    before(:each) do
      login user
      click_link change_password
    end

    it "missing old password" do
      click_button save

      expect(page).to have_css(failure, text: "invalid")
      expect(JournalEntry.users.count).to eq 0
    end

    it "incorrect old password" do
      fill_in old_password, with: "rubbish"
      click_button save

      expect(page).to have_css(failure, text: "invalid")
      expect(JournalEntry.users.count).to eq 0
    end

    it "missing" do
      fill_in old_password, with: fst_password
      click_button save

      expect(page).to have_css(failure, text: "blank")
      expect(JournalEntry.users.count).to eq 0
    end

    it "mismatched" do
      fill_in old_password, with: fst_password
      fill_in new_password_1, with: "p1234567"
      fill_in new_password_2, with: "p7654321"
      click_button save

      expect(page).to have_css(failure, text: "match")
      expect(JournalEntry.users.count).to eq 0
    end

    it "too short" do
      new_password = "p1"
      fill_in old_password, with: fst_password
      fill_in new_password_1, with: new_password
      fill_in new_password_2, with: new_password
      click_button save

      expect(page).to have_css(failure, text: "minimum")
      expect(JournalEntry.users.count).to eq 0
    end

    it "no digits" do
      new_password = "drowsapp"
      fill_in old_password, with: fst_password
      fill_in new_password_1, with: new_password
      fill_in new_password_2, with: new_password
      click_button save

      expect(page).to have_css(failure, text: "digit")
      expect(JournalEntry.users.count).to eq 0
    end

    it "success" do
      new_password = "dr0wsapp"
      fill_in old_password, with: fst_password
      fill_in new_password_1, with: new_password
      fill_in new_password_2, with: new_password
      click_button save

      expect(page).to_not have_css(failure)
      expect(page.title).to eq account
      expect(JournalEntry.users.where(action: "update", column: "encrypted_password", by: user.signature).count).to eq 1
      
      user.reload
      expect(user.valid_password?(fst_password)).to be false
      expect(user.valid_password?(new_password)).to be true
    end
  end
end
