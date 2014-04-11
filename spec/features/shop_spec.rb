require 'spec_helper'

describe "Shop" do
  let(:add_to_cart)     { I18n.t("item.add") }
  let(:cart_link)       { I18n.t("shop.cart.current") + ":" }
  let(:continue)        { I18n.t("shop.cart.continue") }
  let(:cost)            { I18n.t("item.cost") }
  let(:dob)             { I18n.t("player.abbrev.dob") }
  let(:email)           { I18n.t("email") }
  let(:empty)           { I18n.t("shop.cart.empty") }
  let(:fed)             { I18n.t("player.federation") }
  let(:first_name)      { I18n.t("player.first_name") }
  let(:gender)          { I18n.t("player.gender.gender") }
  let(:item)            { I18n.t("item.item") }
  let(:last_name)       { I18n.t("player.last_name") }
  let(:member)          { I18n.t("member") }
  let(:new_member)      { I18n.t("item.member.new") }
  let(:save)            { I18n.t("save") }
  let(:select_member)   { I18n.t("item.member.select") }
  let(:total)           { I18n.t("shop.cart.total") }

  let(:delete)          { "✘" }
  let(:failure)         { "div.alert-danger" }
  let(:force_submit)    { "\n" }
  let(:warning)         { "div.alert-warning" }

  def xpath(type, text, *txts)
    txts.reduce('//tr/%s[contains(.,"%s")]' % [type, text]) do |acc, txt|
      acc + '/following-sibling::%s[contains(.,"%s")]' % [type, txt]
    end
  end

  context "empty cart" do
    it "create before viewing" do
      expect(Cart.count).to eq 0

      visit cart_path
      expect(page).to have_css(warning, text: empty)

      expect(Cart.count).to eq 1
    end
  end

  context "subscriptions", js: true do
    let!(:player)         { create(:player, dob: 58.years.ago.to_date, joined: 30.years.ago.to_date) }
    let!(:player2)        { create(:player, dob: 30.years.ago.to_date, joined: 20.years.ago.to_date) }
    let!(:junior)         { create(:player, dob: 10.years.ago.to_date, joined: 2.years.ago.to_date) }
    let!(:oldie)          { create(:player, dob: 70.years.ago.to_date, joined: 50.years.ago.to_date) }
    let!(:standard_sub)   { create(:subscription_fee, name: "Standard", amount: 35.0) }
    let!(:unemployed_sub) { create(:subscription_fee, name: "Unemployed", amount: 20.0) }
    let!(:under_12_sub)   { create(:subscription_fee, name: "Under 12", amount: 20.0, max_age: 12) }
    let!(:over_65_sub)    { create(:subscription_fee, name: "Over 65", amount: 20.0, min_age: 65) }
    let(:lifetime_sub)    { create(:lifetime_subscription, player: player) }
    let(:existing_sub)    { create(:paid_subscription_item, player: player, fee: standard_sub) }
    let(:newbie)          { create(:new_player, dob: 15.years.ago.to_date) }

    let(:lifetime_error)  { I18n.t("item.error.subscription.lifetime_exists", member: player.name(id: true)) }
    let(:exists_error)    { I18n.t("item.error.subscription.already_exists", member: player.name(id: true), season: standard_sub.season.to_s) }
    let(:in_cart_error)   { I18n.t("item.error.subscription.already_in_cart", member: player.name(id: true), season: standard_sub.season.to_s) }
    let(:too_old_error)   { I18n.t("item.error.age.old", member: player.name, date: under_12_sub.age_ref_date.to_s, limit: under_12_sub.max_age) }
    let(:too_young_error) { I18n.t("item.error.age.young", member: player.name, date: over_65_sub.age_ref_date.to_s, limit: over_65_sub.min_age) }

    it "add" do
      visit shop_path
      expect(page).to_not have_link(cart_link)
      click_link standard_sub.description

      expect(page).to_not have_button(add_to_cart)
      click_button select_member

      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit

      click_link player.id

      click_button add_to_cart

      expect(Cart.count).to eq 1
      expect(Item::Subscription.count).to eq 1
      expect(Item::Subscription.inactive.where(fee: standard_sub, player: player).count).to eq 1

      cart = Cart.last
      subscription = Item::Subscription.last

      expect(page).to have_xpath(xpath("th", item, member, cost))
      expect(page).to have_xpath(xpath("td", subscription.description, player.name(id: true), subscription.cost))
      expect(page).to have_xpath(xpath("th", total, standard_sub.amount))

      expect(subscription).to be_unpaid
      expect(subscription.cart).to eq cart
      expect(subscription.fee).to eq standard_sub
      expect(subscription.player).to eq player

      visit shop_path
      expect(page).to have_link(cart_link)
    end

    it "new member" do
      newbie_fed = ICU::Federation.find(newbie.fed).name
      newbie_sex = I18n.t("player.gender.#{newbie.gender}")

      visit shop_path
      click_link standard_sub.description
      click_button new_member

      fill_in first_name, with: newbie.first_name
      fill_in last_name, with: newbie.last_name
      fill_in dob, with: newbie.dob.to_s
      select newbie_sex, from: gender
      select newbie_fed, from: fed
      fill_in email, with: newbie.email

      click_button save
      expect(page).to_not have_css(failure)

      click_button add_to_cart

      expect(Cart.count).to eq 1
      expect(Item::Subscription.count).to eq 1
      expect(Item::Subscription.inactive.where(fee: standard_sub, player_id: nil).count).to eq 1

      cart = Cart.last
      subscription = Item::Subscription.last

      expect(page).to have_xpath(xpath("th", item, member, cost))
      expect(page).to have_xpath(xpath("td", subscription.description, newbie.name, subscription.cost))
      expect(page).to have_xpath(xpath("th", total, standard_sub.amount))

      expect(subscription).to be_unpaid
      expect(subscription.cart).to eq cart
      expect(subscription.fee).to eq standard_sub
      expect(subscription.player).to be_nil
      expect(subscription.new_player == newbie).to eq true

      click_link continue
      click_link standard_sub.description
      click_button new_member

      fill_in first_name, with: newbie.first_name
      fill_in last_name, with: newbie.last_name
      fill_in dob, with: newbie.dob.to_s
      select newbie_sex, from: gender
      select newbie_fed, from: fed
      fill_in email, with: newbie.email

      click_button save
      click_button add_to_cart
      expect(page).to have_css(failure, text: /already in.*cart/)
    end

    it "duplicate new member" do
      newbie_fed = ICU::Federation.find(player.fed).name
      newbie_sex = I18n.t("player.gender.#{player.gender}")

      visit shop_path
      click_link standard_sub.description
      click_button new_member

      fill_in first_name, with: player.first_name
      fill_in last_name, with: player.last_name
      fill_in dob, with: player.dob.to_s
      select newbie_sex, from: gender
      select newbie_fed, from: fed

      click_button save
      expect(page).to have_css(failure, text: /matches.*#{player.id}/)
      expect(page).to_not have_button(add_to_cart)
    end

    it "blocked by lifetime subscription" do
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
      expect(Item::Subscription.inactive.count).to eq 0
    end

    it "blocked by existing subscription" do
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
      expect(Item::Subscription.inactive.count).to eq 0
    end

    it "blocked by cart duplicate" do
      visit shop_path
      click_link standard_sub.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to_not have_css(failure)

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 1

      visit shop_path
      click_link unemployed_sub.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to have_css(failure, text: in_cart_error)

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 1
    end

    it "too old" do
      visit shop_path
      click_link under_12_sub.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to have_css(failure, text: too_old_error)

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 0

      click_button select_member
      fill_in last_name, with: junior.last_name + force_submit
      fill_in first_name, with: junior.first_name + force_submit
      click_link junior.id
      click_button add_to_cart

      expect(page).to_not have_css(failure)

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 1
    end

    it "too young" do
      visit shop_path
      click_link over_65_sub.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to have_css(failure, text: too_young_error)

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 0

      click_button select_member
      fill_in last_name, with: oldie.last_name + force_submit
      fill_in first_name, with: oldie.first_name + force_submit
      click_link oldie.id
      click_button add_to_cart

      expect(page).to_not have_css(failure)

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 1
    end

    it "delete" do
      visit shop_path
      click_link standard_sub.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to have_xpath(xpath("th", total, standard_sub.amount))

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 1

      visit shop_path
      click_link unemployed_sub.description
      click_button select_member
      fill_in last_name, with: player2.last_name + force_submit
      fill_in first_name, with: player2.first_name + force_submit
      click_link player2.id
      click_button add_to_cart

      expect(page).to have_xpath(xpath("th", total, standard_sub.amount + unemployed_sub.amount))

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 2

      click_link delete, match: :first
      confirm_dialog

      expect(page).to have_xpath(xpath("th", total, unemployed_sub.amount))

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 1

      click_link delete, match: :first
      confirm_dialog

      expect(page).to have_css(warning, text: empty)

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 0
    end

    it "delete from other cart" do
      visit shop_path
      click_link standard_sub.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 1

      cart = Cart.include_items.first
      item = cart.items.first
      other_cart = create(:cart)
      item.cart_id = other_cart.id
      item.save

      expect(cart.items.count).to eq 0
      expect(other_cart.items.count).to eq 1

      click_link delete, match: :first
      confirm_dialog

      expect(page).to have_link(cart_link)

      expect(Cart.count).to eq 2
      expect(Item::Subscription.inactive.count).to eq 1

      expect(cart.items.count).to eq 0
      expect(other_cart.items.count).to eq 1
    end
  end

  context "entries", js: true do
    let!(:player)         { create(:player) }
    let!(:master)         { create(:player, latest_rating: 2400) }
    let!(:beginner)       { create(:player, latest_rating: 1000) }
    let!(:u16)            { create(:player, dob: Date.today.years_ago(15), joined: Date.today.years_ago(5)) }
    let!(:u10)            { create(:player, dob: Date.today.years_ago(9), joined: Date.today.years_ago(1)) }
    let!(:entry_fee)      { create(:entry_fee) }
    let!(:u1400_fee)      { create(:entry_fee, name: "Limerick U1400", max_rating: 1400) }
    let!(:premier_fee)    { create(:entry_fee, name: "Kilbunny Premier", min_rating: 2000) }
    let!(:junior_fee)     { create(:entry_fee, name: "Irish U16", max_age: 15, min_age: 13, age_ref_date: Date.today.months_ago(1)) }

    let(:too_high_error)  { I18n.t("item.error.rating.high", member: master.name, limit: u1400_fee.max_rating) }
    let(:too_low_error)   { I18n.t("item.error.rating.low", member: beginner.name, limit: premier_fee.min_rating) }
    let(:too_old_error)   { I18n.t("item.error.age.old", member: player.name, date: junior_fee.age_ref_date.to_s, limit: junior_fee.max_age) }
    let(:too_young_error) { I18n.t("item.error.age.young", member: u10.name, date: junior_fee.age_ref_date.to_s, limit: junior_fee.min_age) }
    let(:exists_error)    { I18n.t("item.error.entry.already_entered", member: player.name(id: true)) }
    let(:in_cart_error)   { I18n.t("item.error.entry.already_in_cart", member: player.name(id: true)) }

    let(:existing_entry)  { create(:paid_entry_item, player: player, fee: entry_fee) }

    it "add" do
      visit shop_path
      expect(page).to_not have_link(cart_link)
      click_link entry_fee.description

      expect(page).to_not have_button(add_to_cart)
      click_button select_member

      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit

      click_link player.id

      click_button add_to_cart

      expect(Cart.count).to eq 1
      expect(Item::Entry.inactive.where(fee: entry_fee, player: player).count).to eq 1

      cart = Cart.last
      entry = Item::Entry.last

      expect(page).to have_xpath(xpath("th", item, member, cost))
      expect(page).to have_xpath(xpath("td", entry.description, player.name(id: true), entry.cost))
      expect(page).to have_xpath(xpath("th", total, entry.cost))

      visit shop_path
      expect(page).to have_link(cart_link)

      expect(cart).to be_unpaid
      expect(entry.cart).to eq cart
      expect(entry.fee).to eq entry_fee
      expect(entry.player).to eq player

      visit shop_path
      expect(page).to have_link(cart_link)
    end

    it "blocked by existing entry" do
      expect(existing_entry.player).to eq player

      visit shop_path
      click_link entry_fee.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to have_css(failure, text: exists_error)

      expect(Cart.count).to eq 1
      expect(Item::Entry.inactive.count).to eq 0
    end

    it "blocked by cart duplicate" do
      visit shop_path
      click_link entry_fee.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to_not have_css(failure)

      expect(Cart.count).to eq 1
      expect(Item::Entry.inactive.count).to eq 1

      visit shop_path
      click_link entry_fee.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to have_css(failure, text: in_cart_error)

      expect(Cart.count).to eq 1
      expect(Item::Entry.inactive.count).to eq 1
    end

    it "too strong" do
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
      expect(Item::Entry.inactive.count).to eq 1

      visit shop_path
      click_link u1400_fee.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to_not have_css(failure)

      expect(Cart.count).to eq 1
      expect(Item::Entry.inactive.count).to eq 2
    end

    it "too weak" do
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
      expect(Item::Entry.inactive.count).to eq 1

      visit shop_path
      click_link premier_fee.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to_not have_css(failure)

      expect(Cart.count).to eq 1
      expect(Item::Entry.inactive.count).to eq 2
    end

    it "too old or young" do
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
      expect(Item::Entry.inactive.count).to eq 1
    end
  end

  context "select me", js: true do
    let!(:user)             { create(:user) }
    let!(:subscription_fee) { create(:subscription_fee) }
    let!(:entry_fee)        { create(:entry_fee) }

    let(:existing_sub)      { create(:paid_subscription_item, player: user.player, fee: subscription_fee) }
    let(:existing_entry)    { create(:paid_entry_item, player: user.player, fee: entry_fee) }

    let(:cancel)            { I18n.t("cancel") }
    let(:select_me)         { I18n.t("item.member.me") }

    it "guest" do
      visit shop_path
      click_link subscription_fee.description
      expect(page).to_not have_link(select_me, exact: true)

      click_link cancel
      click_link entry_fee.description
      expect(page).to_not have_link(select_me, exact: true)
    end

    it "logged in" do
      login(user)

      visit shop_path
      click_link subscription_fee.description
      expect(page).to have_link(select_me, exact: true)

      click_link cancel
      click_link entry_fee.description
      expect(page).to have_link(select_me, exact: true)

      expect(existing_sub.player).to eq user.player
      expect(existing_entry.player).to eq user.player

      click_link cancel
      click_link subscription_fee.description
      expect(page).to_not have_link(select_me, exact: true)

      click_link cancel
      click_link entry_fee.description
      expect(page).to_not have_link(select_me, exact: true)
    end
  end

  context "user inputs", js: true do
    let!(:player1)        { create(:player) }
    let!(:player2)        { create(:player) }
    let!(:entry_fee)      { create(:entry_fee) }
    let!(:half_point_bye) { create(:half_point_bye, fee: entry_fee) }

    it "option" do
      visit shop_path
      click_link entry_fee.description

      click_button select_member
      fill_in last_name, with: player1.last_name + force_submit
      fill_in first_name, with: player1.first_name + force_submit
      click_link player1.id
      check half_point_bye.label
      click_button add_to_cart

      expect(Item::Entry.inactive.where(fee: entry_fee, player: player1).count).to eq 1
      entry = Item::Entry.last

      expect(entry.player).to eq player1
      expect(entry.notes.size).to eq 1
      expect(entry.notes.first).to eq half_point_bye.label

      click_link continue
      click_link entry_fee.description

      click_button select_member
      fill_in last_name, with: player2.last_name + force_submit
      fill_in first_name, with: player2.first_name + force_submit
      click_link player2.id
      click_button add_to_cart

      expect(Item::Entry.inactive.where(fee: entry_fee, player: player2).count).to eq 1
      entry = Item::Entry.last

      expect(entry.player).to eq player2
      expect(entry.notes).to be_empty
    end
  end
end
