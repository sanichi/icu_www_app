require 'spec_helper'

feature "Cart" do
  given(:cost)            { I18n.t("shop.cart.item.cost") }
  given(:item)            { I18n.t("shop.cart.item.item") }
  given(:member)          { I18n.t("shop.cart.item.member") }
  given(:total)           { I18n.t("shop.cart.total") }

  def xpath(type, text, *txts)
    txts.reduce('//tr/%s[contains(.,"%s")]' % [type, text]) do |acc, txt|
      acc + '/following-sibling::%s[contains(.,"%s")]' % [type, txt]
    end
  end

  scenario "show current before it exists" do
    expect(Cart.count).to eq 0

    visit cart_path
    expect(page).to have_xpath(xpath("th", item, member, cost))
    expect(page).to have_xpath(xpath("th", total, "0.00"))

    expect(Cart.count).to eq 1
  end
end
