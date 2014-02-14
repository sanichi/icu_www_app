require 'spec_helper'

feature "Switch locales" do
  after(:each) do
    Translation.cache.flushdb
  end

  before(:each) do
    create(:translation, locale: "ga", key: "home", english: "Home", value: "Baile")
    create(:translation, locale: "ga", key: "user.lang.en", english: "English", value: "Béarla")
    create(:translation, locale: "ga", key: "user.lang.ga", english: "Irish", value: "Gaeilge")
    create(:translation, locale: "ga", key: "session.sign_in", english: "Sign in", value: "Sínigh isteach")
    create(:translation, locale: "ga", key: "session.sign_out", english: "Sign out", value: "Cláraigh amach")
    create(:translation, locale: "ga", key: "user.preferences", english: "Preferences", value: "Roghanna")
  end

  let(:user) { create(:user) }
  let(:una)  { create(:user, roles: "translator", locale: "ga") }
  let(:mark) { create(:user, roles: "admin") }

  scenario "quest user" do
    visit root_path
    click_link "Home"
    click_link "Irish"
    click_link "Baile"
    click_link "Béarla"
    click_link "Home"
  end

  scenario "default user with preference for English" do
    login user
    click_link "Home"
    click_link "Irish"
    click_link "Baile"
    click_link "Béarla"
    click_link "Home"
    click_link "Irish"
    click_link "Cláraigh amach"
  end

  scenario "user with preference for Irish" do
    login una
    click_link "Baile"
    click_link "Béarla"
    click_link "Home"
    click_link "Irish"
    click_link "Baile"
    click_link "Béarla"
    click_link "Sign out"
  end

  scenario "original language persists" do
    visit home_path
    click_link "Irish"
    %w[Baile Béarla Gaeilge].each { |text| expect(page).to have_link(text) }
    login mark
    %w[Home Logins Translations Preferences English Irish].each { |text| expect(page).to have_link(text) }
    click_link "Sign out"
    %w[Baile Béarla Gaeilge].each { |text| expect(page).to have_link(text) }
    click_link "Béarla"
    %w[Home English Irish].each { |text| expect(page).to have_link(text) }
    login una
    %w[Baile Translations Roghanna Béarla Gaeilge].each { |text| expect(page).to have_link(text) }
    click_link "Cláraigh amach"
    %w[Home English Irish].each { |text| expect(page).to have_link(text) }
  end

  scenario "admin pages and links are in English" do
    login mark
    %w[Home Logins Translations Preferences].each { |text| expect(page).to have_link(text) }
    click_link "Irish"
    %w[Baile Logins Translations Roghanna].each { |text| expect(page).to have_link(text) }
    click_link "Logins"
    %w[Home Logins Translations Preferences].each { |text| expect(page).to have_link(text) }
    click_link "Translations"
    %w[Home Logins Translations Preferences].each { |text| expect(page).to have_link(text) }
    click_link "Home"
    %w[Baile Logins Translations Roghanna].each { |text| expect(page).to have_link(text) }
    click_link "Cláraigh amach"
    %w[Baile Béarla Gaeilge].each { |text| expect(page).to have_link(text) }
  end
end
