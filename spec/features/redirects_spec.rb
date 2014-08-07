require 'rails_helper'

describe "Switch locales" do
  let(:user) { create(:user) }
  let(:una)  { create(:user, roles: "translator", locale: "ga") }
  let(:mark) { create(:user, roles: "admin") }

  after(:each) do
    Translation.cache.flushdb
  end

  before(:each) do
    create(:translation, locale: "ga", key: "shop.shop", english: "Shop", value: "Siopa")
    create(:translation, locale: "ga", key: "user.lang.en", english: "English", value: "Béarla")
    create(:translation, locale: "ga", key: "user.lang.ga", english: "Irish", value: "Gaeilge")
    create(:translation, locale: "ga", key: "session.sign_in", english: "Sign in", value: "Sínigh isteach")
    create(:translation, locale: "ga", key: "session.sign_out", english: "Sign out", value: "Cláraigh amach")
    create(:translation, locale: "ga", key: "user.preferences", english: "Preferences", value: "Roghanna")
  end

  it "quest user" do
    visit root_path
    click_link "Shop"
    click_link "Irish"
    click_link "Siopa"
    click_link "Béarla"
    click_link "Shop"
  end

  it "user with no preference" do
    login user
    click_link "Shop"
    click_link "Irish"
    click_link "Siopa"
    click_link "Béarla"
    click_link "Shop"
    click_link "Irish"
    click_link "Cláraigh amach"
  end

  it "user with preference for Irish" do
    login una
    click_link "Siopa"
    click_link "Béarla"
    click_link "Shop"
    click_link "Irish"
    click_link "Siopa"
    click_link "Béarla"
    click_link "Sign out"
  end

  it "original language persists" do
    visit home_path
    click_link "Irish"
    %w[Siopa Béarla Gaeilge].each { |text| expect(page).to have_link(text) }
    login mark
    %w[Shop Logins Translations Preferences English Irish].each { |text| expect(page).to have_link(text) }
    click_link "Sign out"
    %w[Siopa Béarla Gaeilge].each { |text| expect(page).to have_link(text) }
    click_link "Béarla"
    %w[Shop English Irish].each { |text| expect(page).to have_link(text) }
    login una
    %w[Siopa Translations Roghanna Béarla Gaeilge].each { |text| expect(page).to have_link(text) }
    click_link "Cláraigh amach"
    %w[Shop English Irish].each { |text| expect(page).to have_link(text) }
  end

  it "admin pages and links are in English" do
    login mark
    %w[Shop Logins Translations Preferences].each { |text| expect(page).to have_link(text) }
    click_link "Irish"
    %w[Siopa Logins Translations Roghanna].each { |text| expect(page).to have_link(text) }
    click_link "Logins"
    %w[Shop Logins Translations Preferences].each { |text| expect(page).to have_link(text) }
    click_link "Translations"
    %w[Shop Logins Translations Preferences].each { |text| expect(page).to have_link(text) }
    click_link "Shop"
    %w[Siopa Logins Translations Roghanna].each { |text| expect(page).to have_link(text) }
    click_link "Cláraigh amach"
    %w[Shop English Irish].each { |text| expect(page).to have_link(text) }
  end
end
