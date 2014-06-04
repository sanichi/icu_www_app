require 'spec_helper'

describe User do
  let(:edit)            { I18n.t("edit") }
  let(:english)         { I18n.t("user.lang.en") }
  let(:irish)           { I18n.t("user.lang.ga") }
  let(:irish_ga)        { I18n.t("user.lang.ga", locale: "ga") }
  let(:locale_menu)     { I18n.t("user.locale") }
  let(:locale_menu_ga)  { I18n.t("user.locale", locale: "ga") }
  let(:preferences)     { I18n.t("user.preferences") }
  let(:save)            { I18n.t("save") }
  let(:signed_in_as)    { I18n.t("session.signed_in_as") }
  let(:theme_menu)      { I18n.t("user.theme") }
  let(:unauthorized)    { I18n.t("errors.alerts.unauthorized") }
  let(:updated)         { I18n.t("user.updated") }

  let(:failure) { "div.alert-danger" }
  let(:success) { "div.alert-success" }

  context "authorization" do
    let!(:other_user) { create(:user) }
    let(:paths)       { [account_path(user), preferences_path(user)] }
    let!(:user)       { create(:user) }

    it "a user can manage their own preferences" do
      login user
      paths.each do |path|
        visit path
        expect(page).to_not have_css(failure)
      end
    end

    it "other users cannot manage a user's login" do
      login other_user
      paths.each do |path|
        visit path
        expect(page).to have_css(failure, unauthorized)
      end
    end
  end

  context "preferences" do
    let(:user)  { create(:user) }
    let(:theme) { User::THEMES.reject{ |t| t == User::DEFAULT_THEME }.sample }

    it "change theme", js: true do
      expect(user.theme).to be_nil
      login user
      click_link user.player.name
      click_link preferences
      select theme, from: theme_menu
      expect(page).to have_xpath("/html/head/link[@rel='stylesheet' and starts-with(@href,'/assets/#{theme.downcase}.min.css')]", visible: false)
      expect(page).to have_select(theme_menu, selected: theme)
      user.reload
      expect(user.theme).to eq(theme)
    end

    it "change locale", js: true do
      expect(user.locale).to eq("en")
      login user
      click_link user.player.name
      click_link preferences
      select irish, from: locale_menu
      expect(page).to have_select(locale_menu_ga, selected: irish_ga)
      user.reload
      expect(user.locale).to eq("ga")
    end
  end
end
