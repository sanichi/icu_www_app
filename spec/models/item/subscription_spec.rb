require 'spec_helper'

describe Item::Subscription do
  context "relation to fee" do
    let(:item)   { create(:subscription_item) }
    let!(:other) { create(:entry_item) }

    it "copied attributes" do
      expect(item.description).to eq item.fee.description(:full)
      expect(item.start_date).to eq item.fee.start_date
      expect(item.end_date).to eq item.fee.end_date
      expect(item.cost).to eq item.fee.amount
    end

    it "reverse association" do
      expect(item.fee.items.size).to eq 1
      expect(item.fee.items.first).to eq item
    end
  end

  context "legacy subscription" do
    let(:item) { create(:legacy_subscription_item) }

    it "should have no fee" do
      expect(item.fee).to be_nil
      expect(item.source).to eq "www1"
    end

    it "normally a fee is required" do
      expect{create(:nofee_subscription_item)}.to raise_error
    end
  end

  context "duplicates" do
    let(:last_year) { create(:subscription_fee, years: "2012-13") }
    let(:this_year) { create(:subscription_fee, years: "2013-14") }
    let(:player)    { create(:player) }
    let(:another)   { create(:player) }
    let(:lifer)     { create(:player) }
    let!(:item)     { create(:paid_subscription_item, fee: last_year, player: player) }
    let!(:lifetime) { create(:lifetime_subscription, player: lifer) }

    it "not for the same player" do
      expect{create(:subscription_item, fee: last_year, player: player)}.to raise_error(/subscribed/)
      expect{create(:subscription_item, fee: last_year, player: lifer)}.to raise_error(/lifetime/)
      expect{create(:subscription_item, fee: this_year, player: lifer)}.to raise_error(/lifetime/)
    end

    it "for a different player or season" do
      expect{create(:subscription_item, fee: last_year, player: another)}.to_not raise_error
      expect{create(:subscription_item, fee: this_year, player: player)}.to_not raise_error
    end

    it "lifetime" do
      expect{create(:lifetime_subscription, player: lifer)}.to raise_error(/lifetime/)
      expect{create(:lifetime_subscription, player: player)}.to_not raise_error
    end
  end

  context "inactive duplicates" do
    let(:fee)       { create(:subscription_fee, years: "2013-14") }
    let(:player)    { create(:player) }
    let(:other)     { create(:player) }
    let!(:unpaid)   { create(:subscription_item, fee: fee, player: player) }
    let!(:refunded) { create(:paid_subscription_item, fee: fee, player: player, status: "refunded") }

    it "are allowed" do
      expect{create(:subscription_item, fee: fee, player: player)}.to_not raise_error
      expect{create(:subscription_item, fee: fee, player: other)}.to_not raise_error
    end
  end

  context "#duplicate_of?" do
    let(:player1)   { create(:player) }
    let(:player2)   { create(:player) }
    let(:fee1)      { create(:subscription_fee, years: "2013-14") }
    let(:fee2)      { create(:subscription_fee, years: "2013-14", name: "Unemployed") }
    let(:fee3)      { create(:subscription_fee, years: "2014-15") }
    let(:item1)     { create(:subscription_item, fee: fee1, player: player1) }

    it "duplicates" do
      expect(create(:subscription_item, fee: fee1, player: player1)).to be_duplicate_of(item1)
      expect(create(:subscription_item, fee: fee2, player: player1)).to be_duplicate_of(item1)
    end

    it "not duplicates" do
      expect(create(:subscription_item, fee: fee3, player: player1)).to_not be_duplicate_of(item1)
      expect(create(:subscription_item, fee: fee1, player: player2)).to_not be_duplicate_of(item1)
    end
  end

  context "age constraints" do
    let(:ago10)     { Date.today.years_ago(10) }
    let(:u18)       { create(:subscription_fee, max_age: 17, name: "Under 18") }
    let(:ago18)     { u18.age_ref_date.years_ago(18) }
    let(:p18_under) { create(:player, dob: ago18.days_since(1), joined: ago10) }
    let(:p18_exact) { create(:player, dob: ago18, joined: ago10) }
    let(:p18_over)  { create(:player, dob: ago18.days_ago(1), joined: ago10) }
    let(:o65)       { create(:subscription_fee, min_age: 66, name: "Over 65") }
    let(:ago66)     { o65.age_ref_date.years_ago(66) }
    let(:p66_under) { create(:player, dob: ago66.days_since(1), joined: ago10) }
    let(:p66_exact) { create(:player, dob: ago66, joined: ago10) }
    let(:p66_over)  { create(:player, dob: ago66.days_ago(1), joined: ago10) }
    let(:p_no_dob)  { create(:player_no_dob) }

    it "max age" do
      expect{create(:subscription_item, fee: u18, player: p18_under)}.to_not raise_error
      expect{create(:subscription_item, fee: u18, player: p18_exact)}.to raise_error(/over|old/)
      expect{create(:subscription_item, fee: u18, player: p18_over)}.to raise_error(/over|old/)
      expect{create(:subscription_item, fee: u18, player: p_no_dob)}.to_not raise_error
    end

    it "min age" do
      expect{create(:subscription_item, fee: o65, player: p66_under)}.to raise_error(/under|young/)
      expect{create(:subscription_item, fee: o65, player: p66_exact)}.to_not raise_error
      expect{create(:subscription_item, fee: o65, player: p66_over)}.to_not raise_error
      expect{create(:subscription_item, fee: o65, player: p_no_dob)}.to_not raise_error
    end
  end

  context "player data" do
    let(:new_player_json) { build(:new_player).to_json }

    it "blank" do
      item = build(:subscription_item, player_data: "")
      expect(item).to be_valid
      expect(item.player_data).to be_nil
    end

    it "present with player" do
      expect(build(:subscription_item, player_data: new_player_json)).to be_valid
    end

    it "present without player" do
      expect(build(:subscription_item, player_data: new_player_json, player: nil)).to be_valid
    end
  end
end
