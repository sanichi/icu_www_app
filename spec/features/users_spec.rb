require 'spec_helper'

describe "Authorization for preferences" do
  let!(:user)           { create(:user) }
  let!(:other_user)     { create(:user) }
  let(:paths)           { [account_path(user), preferences_path(user)] }
  let(:success)         { "div.alert-success" }
  let(:failure)         { "div.alert-danger" }
  let(:unauthorized)    { I18n.t("errors.alerts.unauthorized") }
  let(:signed_in_as)    { I18n.t("session.signed_in_as") }

  it "a user can manage their own login" do
    login user
    expect(page).to have_css(success, text: signed_in_as)
    paths.each do |path|
      visit path
      expect(page).to_not have_css(failure)
    end
  end

  it "other users cannot manage a user's login" do
    login other_user
    expect(page).to have_css(success, text: signed_in_as)
    paths.each do |path|
      visit path
      expect(page).to have_css(failure, unauthorized)
    end
  end
end

describe "Edit preferences" do
  let!(:user)           { create(:user) }
  let(:success)         { "div.alert-success" }
  let(:theme)           { User::THEMES.reject{ |t| t == User::DEFAULT_THEME }.sample }
  let(:bootstrap)       { "Bootstrap" }
  let(:theme_label)     { I18n.t("user.theme") }
  let(:locale_label)    { I18n.t("user.locale") }
  let(:english)         { I18n.t("user.lang.en") }
  let(:irish)           { I18n.t("user.lang.ga") }
  let(:locale_label_ga) { I18n.t("user.locale", locale: "ga") }
  let(:irish_ga)        { I18n.t("user.lang.ga", locale: "ga") }
  let(:preferences)     { I18n.t("user.preferences") }
  let(:updated)         { I18n.t("user.updated") }
  let(:edit)            { I18n.t("edit") }
  let(:save)            { I18n.t("save") }

  it "change theme", js: true do
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

  it "change locale", js: true do
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
