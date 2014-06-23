require 'rails_helper'

describe User do
  include_context "features"

  let(:english)        { I18n.t("user.lang.en") }
  let(:irish)          { I18n.t("user.lang.ga") }
  let(:irish_ga)       { I18n.t("user.lang.ga", locale: "ga") }
  let(:locale)         { I18n.t("user.locale") }
  let(:locale_ga)      { I18n.t("user.locale", locale: "ga") }
  let(:preferences)    { I18n.t("user.preferences") }
  let(:signed_in_as)   { I18n.t("session.signed_in_as") }
  let(:theme)          { I18n.t("user.theme") }

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
end
