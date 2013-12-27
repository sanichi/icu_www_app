require 'spec_helper'

feature "Shop" do
  given!(:player)         { create(:player) }
  given!(:standard_sub)   { create(:subscription_fee, category: "standard", amount: 35.0) }
  given!(:unemployed_sub) { create(:subscription_fee, category: "unemployed", amount: 20.0) }

  given(:season_desc)     { Season.new.desc }
  given(:lifetime_sub)    { create(:subscription, player: player, subscription_fee: nil, category: "lifetime", cost: 0.0, season_desc: nil) }
  given(:existing_sub)    { create(:subscription, player: player, subscription_fee: nil, category: "standard", cost: 35.0, season_desc: season_desc) }

  given(:add_to_cart)     { I18n.t("shop.cart.item.add") }
  given(:cost)            { I18n.t("shop.cart.item.cost") }
  given(:item)            { I18n.t("shop.cart.item.item") }
  given(:member)          { I18n.t("shop.cart.item.member") }
  given(:total)           { I18n.t("shop.cart.total") }
  given(:cart_link)       { I18n.t("shop.cart.cart") + ":" }
  given(:first_name)      { I18n.t("player.first_name") }
  given(:last_name)       { I18n.t("player.last_name") }
  given(:select_member)   { I18n.t("shop.cart.item.select_member") }
  given(:reselect_member) { I18n.t("shop.cart.item.reselect_member") }
  given(:lifetime_error)  { I18n.t("fee.subscription.error.lifetime_exists", member: player.name(id: true)) }
  given(:already_error)   { I18n.t("fee.subscription.error.already_exists", member: player.name(id: true), season: season_desc) }

  given(:failure)         { "div.alert-danger" }


  def xpath(type, text, *txts)
    txts.reduce('//tr/%s[contains(.,"%s")]' % [type, text]) do |acc, txt|
      acc + '/following-sibling::%s[contains(.,"%s")]' % [type, txt]
    end
  end

  scenario "add subscription", js: true do
    visit shop_path
    expect(page).to_not have_link(cart_link)
    click_link standard_sub.description

    expect(page).to_not have_button(add_to_cart)
    click_button select_member

    fill_in last_name, with: player.last_name

    fill_in first_name, with: player.first_name

    click_link player.id

    expect(page).to_not have_button(select_member)
    expect(page).to have_button(reselect_member)
    click_button add_to_cart

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 1
    expect(Subscription.where(active: false).count).to eq 1

    cart = Cart.last
    cart_item = CartItem.last
    subscription = Subscription.last

    expect(page).to have_xpath(xpath("th", item, member, cost))
    expect(page).to have_xpath(xpath("td", subscription.description, player.name(id: true), subscription.cost))
    expect(page).to have_xpath(xpath("th", total, standard_sub.cost))

    visit shop_path
    expect(page).to have_link(cart_link)

    expect(cart.status).to eq "unpaid"
    expect(cart_item.status).to eq "unpaid"
    expect(subscription.active).to be_false
    expect(subscription.season_desc).to eq season_desc

    expect(cart_item.cart).to eq cart
    expect(cart_item.cartable).to eq subscription
    expect(subscription.cart_item).to eq cart_item
    expect(subscription.subscription_fee).to eq standard_sub
  end

  scenario "failed add because of lifetime subscription", js: true do
    expect(lifetime_sub.player).to eq player

    visit shop_path
    click_link standard_sub.description
    click_button select_member
    fill_in last_name, with: player.last_name
    fill_in first_name, with: player.first_name
    click_link player.id
    click_button add_to_cart

    expect(page).to have_css(failure, lifetime_error)

    expect(Cart.count).to eq 0
    expect(CartItem.count).to eq 0
    expect(Subscription.where(active: false).count).to eq 0
  end

  scenario "failed add because of existing subscription", js: true do
    expect(existing_sub.player).to eq player

    visit shop_path
    click_link standard_sub.description
    click_button select_member
    fill_in last_name, with: player.last_name
    fill_in first_name, with: player.first_name
    click_link player.id
    click_button add_to_cart

    expect(page).to have_css(failure, already_error)

    expect(Cart.count).to eq 0
    expect(CartItem.count).to eq 0
    expect(Subscription.where(active: false).count).to eq 0
  end
end
