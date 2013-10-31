# encoding: utf-8
require 'spec_helper'

feature "Authorization for translations" do
  given(:ok_roles)        { %w[admin translator] }
  given(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) } }
  given(:translation)     { FactoryGirl.create(:translation) }
  given(:paths)           { [admin_translations_path, admin_translation_path(translation), edit_admin_translation_path(translation)] }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:unauthorized)    { I18n.t("errors.messages.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }

  scenario "the admin and translator roles can manage translations" do
    ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      paths.each do |path|
        visit path
        expect(page).to_not have_css(failure)
      end
    end
  end

  scenario "other roles cannot access translations" do
    not_ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      paths.each do |path|
        visit path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end

  scenario "guests cannot access users" do
    logout
    paths.each do |path|
      visit path
      expect(page).to have_css(failure, text: unauthorized)
    end
  end
end

feature "Performing translations" do
  before(:each) do
    Translation.update_db
    @count = Translation.count
  end

  after(:each) do
    Translation.cache.flushdb
  end

  given(:success)   { "div.alert-success" }
  given(:failure)   { "div.alert-danger" }
  given(:creatable) { "a.btn.btn-success" }
  given(:updatable) { "a.btn.btn-primary" }

  scenario "find and translate an untranslated english phrase" do
    key = "user.role.translator"
    translation = Translation.find_by(key: key)
    irish = "Aistritheoir"

    login "translator"
    visit admin_translations_path
    expect(page).to have_css(creatable, text: @count)
    expect(page).to have_link("Translate", count: Translation::PAGE_SIZE)

    fill_in "Key", with: key
    click_button "Search"
    expect(page).to have_link("Translate", count: 1)

    click_link "Translate"
    fill_in "translation_value", with: irish

    click_button "Save"
    expect(page).to have_xpath("//th[.='Key']/following-sibling::td[.='#{key}']")
    expect(page).to have_xpath("//th[.='English']/following-sibling::td[.='#{translation.english}']")
    expect(page).to have_xpath("//th[.='Irish']/following-sibling::td[.='#{irish}']")

    click_link I18n.t("last_search")
    expect(page).to have_link("Edit", count: 1)
    expect(page).to have_css(creatable, text: @count - 1)
  end

  scenario "find and retranslate an updated english phrase" do
    key = "user.role.admin"
    translation = Translation.find_by(key: key)
    old_english = "God"
    old_irish = "Dia"
    irish = "Riarthóir"
    english = translation.english
    expect(translation.old_english).to eq(english)

    translation.old_english = old_english
    translation.value = old_irish
    translation.user = "Una"
    translation.save

    login "translator"
    visit admin_translations_path
    expect(page).to have_css(creatable, text: @count - 1)
    expect(page).to have_css(updatable, text: 1)

    fill_in "English", with: translation.english
    click_button "Search"
    expect(page).to have_link("Retranslate", count: 1)

    click_link key
    expect(page).to have_xpath("//th[.='Key']/following-sibling::td[.='#{key}']")
    expect(page).to have_xpath("//th[.='Previous English']/following-sibling::td[.='#{translation.old_english}']")
    expect(page).to have_xpath("//th[.='Previous Irish']/following-sibling::td[.='#{old_irish}']")
    expect(page).to have_xpath("//th[.='Current English']/following-sibling::td[.='#{english}']")
    expect(page).to have_xpath("//th[.='Current Irish']/following-sibling::td[.='#{old_irish}']")

    click_link "Retranslate"
    fill_in "translation_value", with: irish
    click_button "Save"
    expect(page).to have_xpath("//th[.='Key']/following-sibling::td[.='#{key}']")
    expect(page).to have_xpath("//th[.='English']/following-sibling::td[.='#{translation.english}']")
    expect(page).to have_xpath("//th[.='Irish']/following-sibling::td[.='#{irish}']")

    click_link I18n.t("last_search")
    expect(page).to have_link("Edit", count: 1)
    expect(page).to have_css(creatable, text: @count - 1)
    expect(page).to_not have_css(updatable)
    expect(page).to have_xpath("//td[.='#{english}']/following-sibling::td[.='#{irish}']")
  end

  scenario "translate a phrase with interpolated variables" do
    key = "errors.attributes.password.length"
    translation = Translation.find_by(key: key)

    login "translator"
    visit admin_translations_path

    fill_in "Key", with: key
    click_button "Search"
    expect(page).to have_link("Translate", count: 1)

    click_link "Translate"
    fill_in "translation_value", with: "Is fhad íosta %{wrong_variable_name}"

    click_button "Save"
    expect(page).to have_css(failure, text: "Translation should have same interpolated variables as English")

    fill_in "translation_value", with: "Is fhad íosta %{minimum}"

    click_button "Save"
    expect(page).to have_css(success, text: "Translation #{translation.locale_key} was updated")
  end

  scenario "find and delete an inactive translation" do
    key = "user.role.wago"
    FactoryGirl.create(:translation, key: key, english: "WogoWago", active: false)

    login "translator"
    visit admin_translations_path
    expect(page).to have_css(creatable, text: @count)

    select "Deletable", from: "category"
    click_button "Search"
    expect(page).to have_link("Delete", count: 1)

    click_link "Delete"
    expect(page).to have_css("div.alert.alert-warning", text: "No matches")
  end

  scenario "translation errors" do
    key = "user.role.admin"
    admin = Translation.find_by(key: key)

    login "translator"
    visit admin_translations_path
    fill_in "Key", with: key
    click_button "Search"
    expect(page).to have_link("Translate", count: 1)

    click_link "Translate"
    fill_in "translation_value", with: ""

    click_button "Save"
    expect(page).to have_css(failure, text: "blank")
    fill_in "translation_value", with: '"Dia"'

    click_button "Save"
    expect(page).to have_css(failure, text: "quote")
  end
end
