require 'rails_helper'

describe "Header", js: true do
  include_context "features"

  let(:hide) { I18n.t("symbol.hide") }
  let(:show) { I18n.t("symbol.show") }
  let(:ticu) { I18n.t("icu.ticu") }

  it "can be hidden and shown" do
    visit home_path
    expect(page).to have_css("#header", text: ticu)

    click_link hide
    expect(page).to_not have_css("#header", text: ticu)
    
    visit help_index_path
    expect(page).to_not have_css("#header", text: ticu)

    click_link show
    expect(page).to have_css("#header", text: ticu)

    visit shop_path
    expect(page).to have_css("#header", text: ticu)
  end
end
