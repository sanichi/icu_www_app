require 'rails_helper'

describe IcuController do
  include_context "features"

  context "authorization" do
    it "anyone can see all pages" do
      Global::ICU_PAGES.each do |key|
        visit self.send("icu_#{key}_path")
        expect(page).to_not have_css(failure)
        expect(page).to have_title(I18n.t("icu.#{key}"))
      end
    end

    it "anyone can see all docs" do
      Global::ICU_DOCS.keys.each do |key|
        visit self.send("icu_#{key}_path")
        expect(page).to_not have_css(failure)
        expect(page).to have_title(I18n.t("icu.#{key}"))
      end
    end
  end
end
