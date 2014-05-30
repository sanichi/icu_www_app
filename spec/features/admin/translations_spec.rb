require 'spec_helper'

describe "Authorization for translations" do
  let(:ok_roles)        { %w[admin translator] }
  let(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) }.append("guest") }
  let(:translation)     { create(:translation) }
  let(:paths)           { [admin_translations_path, admin_translation_path(translation), edit_admin_translation_path(translation)] }
  let(:success)         { "div.alert-success" }
  let(:failure)         { "div.alert-danger" }
  let(:unauthorized)    { I18n.t("errors.alerts.unauthorized") }

  it "some roles can manage translations" do
    ok_roles.each do |role|
      login role
      paths.each do |path|
        visit path
        expect(page).to_not have_css(failure)
      end
    end
  end

  it "other roles and guests have no access" do
    not_ok_roles.each do |role|
      login role
      paths.each do |path|
        visit path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end
end

describe "Performing translations" do
  before(:each) do
    Translation.update_db
    @count = Translation.count
  end

  after(:each) do
    Translation.cache.flushdb
  end

  let(:success)   { "div.alert-success" }
  let(:failure)   { "div.alert-danger" }
  let(:creatable) { "a.btn.btn-success" }
  let(:updatable) { "a.btn.btn-primary" }

  it "find and translate an untranslated english phrase" do
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

  it "find and retranslate an updated english phrase" do
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

  it "translate a phrase with interpolated variables" do
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

  it "find and delete an inactive translation" do
    key = "user.role.wago"
    create(:translation, key: key, english: "WogoWago", active: false)

    login "translator"
    visit admin_translations_path
    expect(page).to have_css(creatable, text: @count)

    select "Deletable", from: "category"
    click_button "Search"
    expect(page).to have_link("Delete", count: 1)

    click_link "Delete"
    expect(page).to have_css("div.alert.alert-warning", text: "No matches")
  end

  it "translation errors" do
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
