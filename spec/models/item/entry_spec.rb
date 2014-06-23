require 'rails_helper'

describe Item::Entry do
  context "relation to fee" do
    let(:item)   { create(:entry_item) }
    let!(:other) { create(:subscription_item) }

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

  context "duplicates" do
    let(:bunratty)  { create(:entry_fee, name: "Bunratty") }
    let(:kilkenny)  { create(:entry_fee, name: "Kilkenny") }
    let(:player)    { create(:player) }
    let(:reyalp)    { create(:player) }
    let!(:item1)    { create(:paid_entry_item, fee: bunratty, player: player) }
    let!(:item2)    { create(:paid_entry_item, fee: kilkenny, player: reyalp) }

    it "not for the same player in the same tournament" do
      expect{create(:entry_item, fee: bunratty, player: player)}.to raise_error(/entered/)
      expect{create(:entry_item, fee: kilkenny, player: reyalp)}.to raise_error(/entered/)
    end

    it "different player or tournament" do
      expect{create(:entry_item, fee: bunratty, player: reyalp)}.to_not raise_error
      expect{create(:entry_item, fee: kilkenny, player: player)}.to_not raise_error
    end
  end

  context "inactive duplicates" do
    let(:bunratty)  { create(:entry_fee, name: "Bunratty") }
    let(:kilkenny)  { create(:entry_fee, name: "Kilkenny") }
    let(:player)    { create(:player) }
    let(:reyalp)    { create(:player) }
    let!(:item1)    { create(:entry_item, fee: bunratty, player: player) }
    let!(:item2)    { create(:entry_item, fee: kilkenny, player: reyalp) }

    it "are allowed" do
      expect{create(:entry_item, fee: bunratty, player: player)}.to_not raise_error
      expect{create(:entry_item, fee: kilkenny, player: reyalp)}.to_not raise_error
    end
  end

  context "#duplicate_of?" do
    let(:player1)   { create(:player) }
    let(:player2)   { create(:player) }
    let(:fee1)      { create(:entry_fee) }
    let(:fee2)      { create(:entry_fee, name: "Challengers") }
    let(:item1)     { create(:entry_item, fee: fee1, player: player1) }

    it "duplicates" do
      expect(create(:entry_item, fee: fee1, player: player1)).to be_duplicate_of(item1)
    end

    it "not duplicates" do
      expect(create(:entry_item, fee: fee1, player: player2)).to_not be_duplicate_of(item1)
      expect(create(:entry_item, fee: fee2, player: player1)).to_not be_duplicate_of(item1)
    end
  end

  context "rating constraints" do
    let(:fee)         { create(:entry_fee, min_rating: 1400, max_rating: 1800, name: "Major") }
    let(:p1400_under) { create(:player, latest_rating: 1399) }
    let(:p1400_exact) { create(:player, latest_rating: 1400) }
    let(:p1400_over)  { create(:player, latest_rating: 1401) }
    let(:p1800_under) { create(:player, latest_rating: 1799) }
    let(:p1800_exact) { create(:player, latest_rating: 1800) }
    let(:p1800_over)  { create(:player, latest_rating: 1801) }
    let(:p_no_rating) { create(:player, latest_rating: nil) }

    it "min rating" do
      expect{create(:entry_item, fee: fee, player: p1400_under)}.to raise_error(/under/)
      expect{create(:entry_item, fee: fee, player: p1400_exact)}.to_not raise_error
      expect{create(:entry_item, fee: fee, player: p1400_over)}.to_not raise_error
      expect{create(:entry_item, fee: fee, player: p_no_rating)}.to_not raise_error
    end

    it "max rating" do
      expect{create(:entry_item, fee: fee, player: p1800_under)}.to_not raise_error
      expect{create(:entry_item, fee: fee, player: p1800_exact)}.to_not raise_error
      expect{create(:entry_item, fee: fee, player: p1800_over)}.to raise_error(/over/)
      expect{create(:entry_item, fee: fee, player: p_no_rating)}.to_not raise_error
    end
  end

  context "player data" do
    it "blank" do
      item = build(:entry_item, player_data: "")
      expect(item).to be_valid
      expect(item.player_data).to be_nil
    end

    it "present" do
      item = build(:entry_item, player_data: "{}")
      expect(item).to_not be_valid
    end
  end
end
