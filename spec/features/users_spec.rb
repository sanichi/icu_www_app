require 'spec_helper'

feature "Authorization for preferences" do
  given!(:user)           { create(:user) }
  given!(:other_user)     { create(:user) }
  given(:paths)           { [account_path(user), preferences_path(user)] }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:unauthorized)    { I18n.t("errors.alerts.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }

  scenario "a user can manage their own login" do
    login user
    expect(page).to have_css(success, text: signed_in_as)
    paths.each do |path|
      visit path
      expect(page).to_not have_css(failure)
    end
  end

  scenario "other users cannot manage a user's login" do
    login other_user
    expect(page).to have_css(success, text: signed_in_as)
    paths.each do |path|
      visit path
      expect(page).to have_css(failure, unauthorized)
    end
  end
end

feature "Edit preferences" do
  given!(:user)           { create(:user) }
  given(:success)         { "div.alert-success" }
  given(:theme)           { User::THEMES.reject{ |t| t == User::DEFAULT_THEME }.sample }
  given(:bootstrap)       { "Bootstrap" }
  given(:theme_label)     { I18n.t("user.theme") }
  given(:locale_label)    { I18n.t("user.locale") }
  given(:english)         { I18n.t("user.lang.en") }
  given(:irish)           { I18n.t("user.lang.ga") }
  given(:locale_label_ga) { I18n.t("user.locale", locale: "ga") }
  given(:irish_ga)        { I18n.t("user.lang.ga", locale: "ga") }
  given(:preferences)     { I18n.t("user.preferences") }
  given(:updated)         { I18n.t("user.updated") }
  given(:edit)            { I18n.t("edit") }
  given(:save)            { I18n.t("save") }

  scenario "change theme", js: true do
    expect(user.theme).to be_nil
    login user
    click_link user.player.name
    click_link preferences
    select theme, from: theme_label
    expect(page).to have_xpath("/html/head/link[@rel='stylesheet' and starts-with(@href,'/assets/#{theme.downcase}.min.css')]", visible: false)
    expect(page).to have_select(theme_label, selected: theme)
    user.reload
    expect(user.theme).to eq(theme)
  end

  scenario "change locale", js: true do
    expect(user.locale).to eq("en")
    login user
    click_link user.player.name
    click_link preferences
    select irish, from: locale_label
    expect(page).to have_select(locale_label_ga, selected: irish_ga)
    user.reload
    expect(user.locale).to eq("ga")
  end
end
