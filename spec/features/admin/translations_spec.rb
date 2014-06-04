require 'spec_helper'

describe Translation do
  let(:save)         { I18n.t("save") }
  let(:search)       { I18n.t("search") }
  let(:last_search)  { I18n.t("last_search") }
  let(:unauthorized) { I18n.t("errors.alerts.unauthorized") }

  let(:failure) { "div.alert-danger" }
  let(:success) { "div.alert-success" }

  context "authorization" do
    let(:level1)      { %w[admin translator] }
    let(:level2)      { User::ROLES.reject { |role| level1.include?(role) }.append("guest") }
    let(:paths)       { [admin_translations_path, admin_translation_path(translation), edit_admin_translation_path(translation)] }
    let(:translation) { create(:translation) }

    it "level1 can manage translations" do
      level1.each do |role|
        login role
        paths.each do |path|
          visit path
          expect(page).to_not have_css(failure)
        end
      end
    end

    it "level2 have no access" do
      level2.each do |role|
        login role
        paths.each do |path|
          visit path
          expect(page).to have_css(failure, text: unauthorized)
        end
      end
    end
  end

  context "translation" do
    let(:creatable) { "a.btn.btn-success" }
    let(:updatable) { "a.btn.btn-primary" }

    before(:each) do
      Translation.update_db
      @count = Translation.count
    end

    after(:each) do
      Translation.cache.flushdb
    end

    it "find and translate an untranslated english phrase" do
      key = "user.role.translator"
      translation = Translation.find_by(key: key)
      irish = "Aistritheoir"

      login "translator"
      visit admin_translations_path
      expect(page).to have_css(creatable, text: @count)
      expect(page).to have_link("Translate", count: Translation::PAGE_SIZE)

      fill_in "Key", with: key
      click_button search
      expect(page).to have_link("Translate", count: 1)

      click_link "Translate"
      fill_in "translation_value", with: irish

      click_button save
      expect(page).to have_xpath("//th[.='Key']/following-sibling::td[.='#{key}']")
      expect(page).to have_xpath("//th[.='English']/following-sibling::td[.='#{translation.english}']")
      expect(page).to have_xpath("//th[.='Irish']/following-sibling::td[.='#{irish}']")

      click_link last_search
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
      click_button search
      expect(page).to have_link("Retranslate", count: 1)

      click_link key
      expect(page).to have_xpath("//th[.='Key']/following-sibling::td[.='#{key}']")
      expect(page).to have_xpath("//th[.='Previous English']/following-sibling::td[.='#{translation.old_english}']")
      expect(page).to have_xpath("//th[.='Previous Irish']/following-sibling::td[.='#{old_irish}']")
      expect(page).to have_xpath("//th[.='Current English']/following-sibling::td[.='#{english}']")
      expect(page).to have_xpath("//th[.='Current Irish']/following-sibling::td[.='#{old_irish}']")

      click_link "Retranslate"
      fill_in "translation_value", with: irish
      click_button save
      expect(page).to have_xpath("//th[.='Key']/following-sibling::td[.='#{key}']")
      expect(page).to have_xpath("//th[.='English']/following-sibling::td[.='#{translation.english}']")
      expect(page).to have_xpath("//th[.='Irish']/following-sibling::td[.='#{irish}']")

      click_link last_search
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
      click_button search
      expect(page).to have_link("Translate", count: 1)

      click_link "Translate"
      fill_in "translation_value", with: "Is fhad íosta %{wrong_variable_name}"

      click_button save
      expect(page).to have_css(failure, text: "Translation should have same interpolated variables as English")

      fill_in "translation_value", with: "Is fhad íosta %{minimum}"

      click_button save
      expect(page).to have_css(success, text: "Translation #{translation.locale_key} was updated")
    end

    it "find and delete an inactive translation" do
      key = "user.role.wago"
      create(:translation, key: key, english: "WogoWago", active: false)

      login "translator"
      visit admin_translations_path
      expect(page).to have_css(creatable, text: @count)

      select "Deletable", from: "category"
      click_button search
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
      click_button search
      expect(page).to have_link("Translate", count: 1)

      click_link "Translate"
      fill_in "translation_value", with: ""

      click_button save
      expect(page).to have_css(failure, text: "blank")
      fill_in "translation_value", with: '"Dia"'

      click_button save
      expect(page).to have_css(failure, text: "quote")
    end
  end
end
