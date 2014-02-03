require 'spec_helper'

feature "Shop for subscriptions" do
  given!(:player)         { create(:player, dob: 58.years.ago, joined: 30.years.ago) }
  given!(:player2)        { create(:player, dob: 30.years.ago, joined: 20.years.ago) }
  given!(:junior)         { create(:player, dob: 10.years.ago, joined: 2.years.ago) }
  given!(:oldie)          { create(:player, dob: 70.years.ago, joined: 50.years.ago) }
  given!(:standard_sub)   { create(:subscription_fee, category: "standard", amount: 35.0) }
  given!(:unemployed_sub) { create(:subscription_fee, category: "unemployed", amount: 20.0) }
  given!(:under_12_sub)   { create(:subscription_fee, category: "under_12", amount: 20.0) }
  given!(:over_65_sub)    { create(:subscription_fee, category: "over_65", amount: 20.0) }

  given(:season_desc)     { standard_sub.season_desc }
  given(:lifetime_sub)    { create(:subscription, player: player, subscription_fee: nil, category: "lifetime", cost: 0.0, season_desc: nil) }
  given(:existing_sub)    { create(:subscription, player: player, subscription_fee: standard_sub, category: "standard", cost: 35.0, season_desc: season_desc) }

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
  given(:exists_error)    { I18n.t("fee.subscription.error.already_exists", member: player.name(id: true), season: season_desc) }
  given(:in_cart_error)   { I18n.t("fee.subscription.error.already_in_cart", member: player.name(id: true)) }
  given(:too_old_error)   { I18n.t("fee.subscription.error.too_old", member: player.name(id: true), limit: 12, date: under_12_sub.age_ref_date.to_s) }
  given(:too_young_error) { I18n.t("fee.subscription.error.too_young", member: player.name(id: true), limit: 65, date: over_65_sub.age_ref_date.to_s) }

  given(:force_submit)    { "\n" }
  given(:failure)         { "div.alert-danger" }

  def xpath(type, text, *txts)
    txts.reduce('//tr/%s[contains(.,"%s")]' % [type, text]) do |acc, txt|
      acc + '/following-sibling::%s[contains(.,"%s")]' % [type, txt]
    end
  end

  scenario "add", js: true do
    visit shop_path
    expect(page).to_not have_link(cart_link)
    click_link standard_sub.description

    expect(page).to_not have_button(add_to_cart)
    click_button select_member

    fill_in last_name, with: player.last_name + force_submit
    fill_in first_name, with: player.first_name + force_submit

    click_link player.id

    expect(page).to_not have_button(select_member)
    expect(page).to have_button(reselect_member)
    click_button add_to_cart

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 1
    expect(Subscription.inactive.count).to eq 1

    cart = Cart.last
    cart_item = CartItem.last
    subscription = Subscription.last

    expect(page).to have_xpath(xpath("th", item, member, cost))
    expect(page).to have_xpath(xpath("td", subscription.description, player.name(id: true), subscription.cost))
    expect(page).to have_xpath(xpath("th", total, standard_sub.cost))

    visit shop_path
    expect(page).to have_link(cart_link)

    expect(subscription.season_desc).to eq season_desc
    expect(subscription.unpaid?).to be_true

    expect(cart_item.cart).to eq cart
    expect(cart_item.cartable).to eq subscription
    expect(subscription.cart_item).to eq cart_item
    expect(subscription.subscription_fee).to eq standard_sub
  end

  scenario "can't add due to existing lifetime subscription", js: true do
    expect(lifetime_sub.player).to eq player

    visit shop_path
    click_link standard_sub.description
    click_button select_member
    fill_in last_name, with: player.last_name + force_submit
    fill_in first_name, with: player.first_name + force_submit
    click_link player.id
    click_button add_to_cart

    expect(page).to have_css(failure, text: lifetime_error)

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 0
    expect(Subscription.inactive.count).to eq 0
  end

  scenario "can't add due to existing subscription for the season", js: true do
    expect(existing_sub.player).to eq player

    visit shop_path
    click_link standard_sub.description
    click_button select_member
    fill_in last_name, with: player.last_name + force_submit
    fill_in first_name, with: player.first_name + force_submit
    click_link player.id
    click_button add_to_cart

    expect(page).to have_css(failure, text: exists_error)

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 0
    expect(Subscription.inactive.count).to eq 0
  end

  scenario "can't add due to duplicate subscription in cart", js: true do
    visit shop_path
    click_link standard_sub.description
    click_button select_member
    fill_in last_name, with: player.last_name + force_submit
    fill_in first_name, with: player.first_name + force_submit
    click_link player.id
    click_button add_to_cart

    expect(page).to_not have_css(failure)

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 1
    expect(Subscription.inactive.count).to eq 1

    visit shop_path
    click_link unemployed_sub.description
    click_button select_member
    fill_in last_name, with: player.last_name + force_submit
    fill_in first_name, with: player.first_name + force_submit
    click_link player.id
    click_button add_to_cart

    expect(page).to have_css(failure, text: in_cart_error)

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 1
    expect(Subscription.inactive.count).to eq 1
  end

  scenario "can't add due to age (too old)", js: true do
    visit shop_path
    click_link under_12_sub.description
    click_button select_member
    fill_in last_name, with: player.last_name + force_submit
    fill_in first_name, with: player.first_name + force_submit
    click_link player.id
    click_button add_to_cart

    expect(page).to have_css(failure, text: too_old_error)

    click_button select_member
    fill_in last_name, with: junior.last_name + force_submit
    fill_in first_name, with: junior.first_name + force_submit
    click_link junior.id
    click_button add_to_cart

    expect(page).to_not have_css(failure)

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 1
    expect(Subscription.inactive.where(category: "under_12").count).to eq 1
  end

  scenario "can't add due to age (too young)", js: true do
    visit shop_path
    click_link over_65_sub.description
    click_button select_member
    fill_in last_name, with: player.last_name + force_submit
    fill_in first_name, with: player.first_name + force_submit
    click_link player.id
    click_button add_to_cart

    expect(page).to have_css(failure, text: too_young_error)

    click_button select_member
    fill_in last_name, with: oldie.last_name + force_submit
    fill_in first_name, with: oldie.first_name + force_submit
    click_link oldie.id
    click_button add_to_cart

    expect(page).to_not have_css(failure)

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 1
    expect(Subscription.inactive.where(category: "over_65").count).to eq 1
  end

  scenario "delete", js: true do
    visit shop_path
    click_link standard_sub.description
    click_button select_member
    fill_in last_name, with: player.last_name + force_submit
    fill_in first_name, with: player.first_name + force_submit
    click_link player.id
    click_button add_to_cart

    expect(page).to have_xpath(xpath("th", total, standard_sub.cost))

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 1
    expect(Subscription.inactive.count).to eq 1

    visit shop_path
    click_link unemployed_sub.description
    click_button select_member
    fill_in last_name, with: player2.last_name + force_submit
    fill_in first_name, with: player2.first_name + force_submit
    click_link player2.id
    click_button add_to_cart

    expect(page).to have_xpath(xpath("th", total, standard_sub.cost + unemployed_sub.cost))

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 2
    expect(Subscription.inactive.count).to eq 2

    click_link "✘", match: :first
    confirm_dialog

    expect(page).to have_xpath(xpath("th", total, unemployed_sub.cost))

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 1
    expect(Subscription.inactive.count).to eq 1

    click_link "✘", match: :first
    confirm_dialog

    expect(page).to have_xpath(xpath("th", total, 0.0))

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 0
    expect(Subscription.inactive.count).to eq 0
  end

  scenario "can only delete from current cart", js: true do
    visit shop_path
    click_link standard_sub.description
    click_button select_member
    fill_in last_name, with: player.last_name + force_submit
    fill_in first_name, with: player.first_name + force_submit
    click_link player.id
    click_button add_to_cart

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 1
    expect(Subscription.inactive.count).to eq 1

    cart = Cart.include_cartables.first
    cart_item = cart.cart_items.first
    other_cart = create(:cart)
    cart_item.cart_id = other_cart.id
    cart_item.save

    expect(cart.items).to eq 0
    expect(other_cart.items).to eq 1

    click_link "✘", match: :first
    confirm_dialog

    expect(page).to have_link(cart_link)

    expect(Cart.count).to eq 2
    expect(CartItem.count).to eq 1
    expect(Subscription.inactive.count).to eq 1

    expect(cart.items).to eq 0
    expect(other_cart.items).to eq 1
  end
end

feature "Shop for entries" do
  given!(:player)         { create(:player) }
  given!(:master)         { create(:player, latest_rating: 2400) }
  given!(:beginner)       { create(:player, latest_rating: 1000) }
  given!(:u16)            { create(:player, dob: Date.today.years_ago(15), joined: Date.today.years_ago(5)) }
  given!(:u10)            { create(:player, dob: Date.today.years_ago(9), joined: Date.today.years_ago(1)) }
  given!(:entry_fee)      { create(:entry_fee) }
  given!(:u1400_fee)      { create(:entry_fee, event_name: "Limerick U1400", max_rating: 1400) }
  given!(:premier_fee)    { create(:entry_fee, event_name: "Kilbunny Premier", min_rating: 2000) }
  given!(:junior_fee)     { create(:entry_fee, event_name: "Irish U16", max_age: 15, min_age: 13, age_ref_date: Date.today.months_ago(1)) }

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
  given(:too_high_error)  { I18n.t("fee.entry.error.rating_too_high", member: master.name, limit: 1400) }
  given(:too_low_error)   { I18n.t("fee.entry.error.rating_too_low", member: beginner.name, limit: 2000) }
  given(:too_old_error)   { I18n.t("fee.entry.error.too_old", member: player.name, limit: junior_fee.max_age, date: junior_fee.age_ref_date) }
  given(:too_young_error) { I18n.t("fee.entry.error.too_young", member: u10.name, limit: junior_fee.min_age, date: junior_fee.age_ref_date) }

  given(:force_submit)    { "\n" }
  given(:failure)         { "div.alert-danger" }

  def xpath(type, text, *txts)
    txts.reduce('//tr/%s[contains(.,"%s")]' % [type, text]) do |acc, txt|
      acc + '/following-sibling::%s[contains(.,"%s")]' % [type, txt]
    end
  end

  scenario "add", js: true do
    visit shop_path
    expect(page).to_not have_link(cart_link)
    click_link entry_fee.description

    expect(page).to_not have_button(add_to_cart)
    click_button select_member

    fill_in last_name, with: player.last_name + force_submit
    fill_in first_name, with: player.first_name + force_submit

    click_link player.id

    expect(page).to_not have_button(select_member)
    expect(page).to have_button(reselect_member)
    click_button add_to_cart

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 1
    expect(Entry.inactive.where(entry_fee_id: entry_fee.id, player_id: player.id).count).to eq 1

    cart = Cart.last
    cart_item = CartItem.last
    entry = Entry.last

    expect(page).to have_xpath(xpath("th", item, member, cost))
    expect(page).to have_xpath(xpath("td", entry.description, player.name(id: true), entry.cost))
    expect(page).to have_xpath(xpath("th", total, entry.cost))

    visit shop_path
    expect(page).to have_link(cart_link)

    expect(cart.unpaid?).to be_true
    expect(entry.unpaid?).to be_true

    expect(cart_item.cart).to eq cart
    expect(cart_item.cartable).to eq entry
    expect(entry.cart_item).to eq cart_item
    expect(entry.entry_fee).to eq entry_fee
  end

  scenario "can't add due to rating (too high)", js: true do
    visit shop_path
    click_link u1400_fee.description
    click_button select_member
    fill_in last_name, with: master.last_name + force_submit
    fill_in first_name, with: master.first_name + force_submit
    click_link master.id
    click_button add_to_cart

    expect(page).to have_css(failure, text: too_high_error)

    click_button select_member
    fill_in last_name, with: beginner.last_name + force_submit
    fill_in first_name, with: beginner.first_name + force_submit
    click_link beginner.id
    click_button add_to_cart

    expect(page).to_not have_css(failure)

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 1
    expect(Entry.inactive.where(entry_fee_id: u1400_fee.id, player_id: beginner.id).count).to eq 1

    visit shop_path
    click_link u1400_fee.description
    click_button select_member
    fill_in last_name, with: player.last_name + force_submit
    fill_in first_name, with: player.first_name + force_submit
    click_link player.id
    click_button add_to_cart

    expect(page).to_not have_css(failure)

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 2
    expect(Entry.inactive.where(entry_fee_id: u1400_fee.id).count).to eq 2
  end

  scenario "can't add due to rating (too low)", js: true do
    visit shop_path
    click_link premier_fee.description
    click_button select_member
    fill_in last_name, with: beginner.last_name + force_submit
    fill_in first_name, with: beginner.first_name + force_submit
    click_link beginner.id
    click_button add_to_cart

    expect(page).to have_css(failure, text: too_low_error)

    click_button select_member
    fill_in last_name, with: master.last_name + force_submit
    fill_in first_name, with: master.first_name + force_submit
    click_link master.id
    click_button add_to_cart

    expect(page).to_not have_css(failure)

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 1
    expect(Entry.inactive.where(entry_fee_id: premier_fee.id, player_id: master.id).count).to eq 1

    visit shop_path
    click_link premier_fee.description
    click_button select_member
    fill_in last_name, with: player.last_name + force_submit
    fill_in first_name, with: player.first_name + force_submit
    click_link player.id
    click_button add_to_cart

    expect(page).to_not have_css(failure)

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 2
    expect(Entry.inactive.where(entry_fee_id: premier_fee.id).count).to eq 2
  end

  scenario "can't add due to age", js: true do
    visit shop_path
    click_link junior_fee.description
    click_button select_member
    fill_in last_name, with: player.last_name + force_submit
    fill_in first_name, with: player.first_name + force_submit
    click_link player.id
    click_button add_to_cart

    expect(page).to have_css(failure, text: too_old_error)

    click_button select_member
    fill_in last_name, with: u10.last_name + force_submit
    fill_in first_name, with: u10.first_name + force_submit
    click_link u10.id
    click_button add_to_cart

    expect(page).to have_css(failure, text: too_young_error)

    click_button select_member
    fill_in last_name, with: u16.last_name + force_submit
    fill_in first_name, with: u16.first_name + force_submit
    click_link u16.id
    click_button add_to_cart
    
    expect(page).to_not have_css(failure)

    expect(Cart.count).to eq 1
    expect(CartItem.count).to eq 1
    expect(Entry.inactive.where(entry_fee_id: junior_fee.id, player_id: u16.id).count).to eq 1
  end
end
