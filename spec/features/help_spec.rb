require 'rails_helper'

describe HelpController do
  include_context "features"

  context "authorization" do
    Global::HELP_PAGES.sort.each do |key|
      it key do
        visit send("help_#{key}_path")
        expect(page).to_not have_css(failure)
        expect(page).to have_css(key == "index" ? "h1" : "h2", text: I18n.t("help.#{key}"))
      end
    end
  end
end
