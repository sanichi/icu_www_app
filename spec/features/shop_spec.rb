require 'spec_helper'

describe "Shop" do
  include_context "features"

  let(:add_to_cart)     { I18n.t("item.add") }
  let(:cart_link)       { I18n.t("shop.cart.current") + ":" }
  let(:continue)        { I18n.t("shop.cart.continue") }
  let(:cost)            { I18n.t("item.cost") }
  let(:dob)             { I18n.t("player.abbrev.dob") }
  let(:empty)           { I18n.t("shop.cart.empty") }
  let(:fed)             { I18n.t("player.federation") }
  let(:first_name)      { I18n.t("player.first_name") }
  let(:gender)          { I18n.t("player.gender.gender") }
  let(:item)            { I18n.t("item.item") }
  let(:last_name)       { I18n.t("player.last_name") }
  let(:new_member)      { I18n.t("item.member.new") }
  let(:select_member)   { I18n.t("item.member.select") }
  let(:total)           { I18n.t("shop.cart.total") }

  let(:delete_cross)    { "✘" }
  let(:force_submit)    { "\n" }

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
      expect(subscription.notes).to be_empty

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
      expect(subscription.notes).to be_empty

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

      click_link delete_cross, match: :first
      confirm_dialog

      expect(page).to have_xpath(xpath("th", total, unemployed_sub.amount))

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 1

      click_link delete_cross, match: :first
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

      click_link delete_cross, match: :first
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
      expect(entry.notes).to be_empty

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

    context "option" do
      it "half-point bye" do
        entry_fee = create(:entry_fee)
        half_point_bye = create(:half_point_bye_option, fee: entry_fee)

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

    context "amount" do
      context "donation" do
        let(:amount)        { create(:donation_amount, min_amount: 10.0) }
        let!(:donation_fee) { create(:donation, user_inputs: [amount]) }

        let(:missing)       { I18n.t("item.error.user_input.amount.missing", label: amount.label) }
        let(:invalid)       { I18n.t("item.error.user_input.amount.invalid", label: amount.label) }
        let(:too_small)     { I18n.t("item.error.user_input.amount.too_small", label: amount.label, min: amount.min_amount) }
        let(:too_large)     { I18n.t("item.error.user_input.amount.too_large", label: amount.label, max: Cart::MAX_AMOUNT) }

        before(:each) do
          visit shop_path
          click_link donation_fee.description
        end

        it "valid amount" do
          fill_in amount.label, with: "1234.567"
          click_button add_to_cart

          expect(Cart.count).to eq 1
          expect(Item::Other.inactive.where(fee: donation_fee).count).to eq 1

          cart = Cart.last
          expect(cart.items.size).to eq 1
          expect(cart.total_cost).to eq 1234.57
          donation = cart.items.first

          expect(donation.cost).to eq 1234.57
          expect(donation.description).to eq "Donation Fee"
          expect(donation.notes).to be_empty
        end

        it "missing, invalid, too low, too high" do
          click_button add_to_cart
          expect(page).to have_css(failure, text: missing)

          fill_in amount.label, with: "loads"
          click_button add_to_cart
          expect(page).to have_css(failure, text: invalid)

          fill_in amount.label, with: (amount.min_amount - 1.0).to_s
          click_button add_to_cart
          expect(page).to have_css(failure, text: too_small)

          fill_in amount.label, with: (Cart::MAX_AMOUNT + 1.0).to_s
          click_button add_to_cart
          expect(page).to have_css(failure, text: too_large)
        end
      end
    end

    context "date" do
      context "rating fee" do
        let!(:player)           { create(:player) }
        let!(:rating_fee)       { create(:foreign_rating_fee) }
        let!(:tournament_name)  { create(:tournament_text, fee: rating_fee) }
        let!(:tournament_start) { create(:tournament_date, fee: rating_fee, date_constraint: "today_or_in_the_future") }

        let(:missing)           { I18n.t("item.error.user_input.date.missing", label: tournament_start.label) }
        let(:invalid)           { I18n.t("item.error.user_input.date.invalid", label: tournament_start.label) }
        let(:in_the_past)       { I18n.t("item.error.user_input.date.today_or_in_the_future", label: tournament_start.label) }

        let(:date)              { Date.today.months_since(1).to_s }
        let(:past_date)         { Date.today.days_ago(1).to_s }
        let(:my_name)           { "Golders Green Weekender" }

        before(:each) do
          visit shop_path
          click_link rating_fee.description
          click_button select_member
          fill_in last_name, with: player.last_name + force_submit
          fill_in first_name, with: player.first_name + force_submit
          click_link player.id
          fill_in tournament_name.label, with: my_name
        end

        it "valid date" do
          fill_in tournament_start.label, with: date
          click_button add_to_cart

          expect(Cart.count).to eq 1
          expect(Item::Other.inactive.where(fee: rating_fee).count).to eq 1

          cart = Cart.last
          expect(cart.items.size).to eq 1
          expect(cart.total_cost).to eq rating_fee.amount
          item = cart.items.first

          expect(item.cost).to eq rating_fee.amount
          expect(item.description).to eq rating_fee.description(:full)
          expect(item.notes.size).to eq 2
          expect(item.notes.include?(my_name)).to be_true
          expect(item.notes.include?(date)).to be_true
        end

        it "missing" do
          click_button add_to_cart
          expect(page).to have_css(failure, text: missing)
        end

        it "invalid" do
          fill_in tournament_start.label, with: "soon"
          click_button add_to_cart
          expect(page).to have_css(failure, text: invalid)
        end

        it "in the past" do
          fill_in tournament_start.label, with: past_date
          click_button add_to_cart
          expect(page).to have_css(failure, text: in_the_past)
        end
      end
    end

    context "text" do
      context "donation" do
        let(:amount)       { create(:donation_amount) }
        let(:donation_fee) { create(:donation, user_inputs: [amount]) }
        let(:message)      { " To   support  ICU   administration  costs  " }

        context "optional comment" do
          let!(:comment) { create(:comment_text, fee: donation_fee) }

          before(:each) do
            visit shop_path
            click_link donation_fee.description
            fill_in amount.label, with: "100"
          end

          it "skip" do
            click_button add_to_cart

            expect(Item::Other.inactive.where(fee: donation_fee).count).to eq 1
            donation = Item::Other.last

            expect(donation.notes).to be_empty
          end

          it "fill in" do
            fill_in comment.label, with: message
            click_button add_to_cart

            expect(Item::Other.inactive.where(fee: donation_fee).count).to eq 1
            donation = Item::Other.last

            expect(donation.notes.size).to eq 1
            expect(donation.notes.first).to eq message.trim
          end
        end

        context "required comment" do
          let!(:comment) { create(:comment_text, fee: donation_fee, required: true) }

          before(:each) do
            visit shop_path
            click_link donation_fee.description
            fill_in amount.label, with: "100"
          end

          it "error if missing" do
            click_button add_to_cart

            expect(page).to have_css(failure, text: I18n.t("item.error.user_input.text.missing", label: comment.label))

            fill_in comment.label, with: message
            click_button add_to_cart

            expect(page).to_not have_css(failure)
            expect(Item::Other.inactive.where(fee: donation_fee).count).to eq 1
            donation = Item::Other.last

            expect(donation.notes.size).to eq 1
            expect(donation.notes.first).to eq message.trim
          end
        end

        context "short comment" do
          let!(:comment) { create(:comment_text, fee: donation_fee, max_length: 10) }

          before(:each) do
            visit shop_path
            click_link donation_fee.description
            fill_in amount.label, with: "100"
          end

          it "fill in" do
            fill_in comment.label, with: "12345678901234567890"
            click_button add_to_cart

            expect(Item::Other.inactive.where(fee: donation_fee).count).to eq 1
            donation = Item::Other.last

            expect(donation.notes.size).to eq 1
            expect(donation.notes.first).to eq "1234567890"
          end
        end
      end
    end
  end
end
