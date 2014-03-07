require 'spec_helper'

describe Item::Subscripsion do
  context "relation to fee" do
    let(:item)   { create(:subscripsion_item) }
    let!(:other) { create(:entri_item) }

    it "copied attributes" do
      expect(item.description).to eq item.fee.description(:full)
      expect(item.start_date).to eq item.fee.start_date
      expect(item.end_date).to eq item.fee.end_date
      expect(item.cost).to eq item.fee.amount
    end

    it "reverse association" do
      expect(item.fee.items.size).to eq 1
      expect(item.fee.items.first).to eq item
      # expect(item.fee.items.first.object_id).to eq item.object_id
    end
  end

  context "legacy subscription" do
    let(:item) { create(:legacy_subscripsion_item) }

    it "should have no fee" do
      expect(item.fee).to be_nil
      expect(item.source).to eq "www1"
    end

    it "normally a fee is required" do
      expect{create(:nofee_subscripsion_item)}.to raise_error
    end
  end

  context "duplicates" do
    let(:last_year) { create(:subscripsion_fee, years: "2012-13") }
    let(:this_year) { create(:subscripsion_fee, years: "2013-14") }
    let(:player)    { create(:player) }
    let(:another)   { create(:player) }
    let(:lifer)     { create(:player) }
    let!(:item)     { create(:paid_subscripsion_item, fee: last_year, player: player) }
    let!(:lifetime) { create(:lifetime_subscripsion, player: lifer) }

    it "not for the same player" do
      expect{create(:subscripsion_item, fee: last_year, player: player)}.to raise_error(/subscribed/)
      expect{create(:subscripsion_item, fee: last_year, player: lifer)}.to raise_error(/lifetime/)
      expect{create(:subscripsion_item, fee: this_year, player: lifer)}.to raise_error(/lifetime/)
    end

    it "for a different player or season" do
      expect{create(:subscripsion_item, fee: last_year, player: another)}.to_not raise_error
      expect{create(:subscripsion_item, fee: this_year, player: player)}.to_not raise_error
    end

    it "lifetime" do
      expect{create(:lifetime_subscripsion, player: lifer)}.to raise_error(/lifetime/)
      expect{create(:lifetime_subscripsion, player: player)}.to_not raise_error
    end
  end

  context "inactive duplicates" do
    let(:fee)       { create(:subscripsion_fee, years: "2013-14") }
    let(:player)    { create(:player) }
    let(:other)     { create(:player) }
    let!(:unpaid)   { create(:subscripsion_item, fee: fee, player: player) }
    let!(:refunded) { create(:paid_subscripsion_item, fee: fee, player: player, status: "refunded") }

    it "are allowed" do
      expect{create(:subscripsion_item, fee: fee, player: player)}.to_not raise_error
      expect{create(:subscripsion_item, fee: fee, player: other)}.to_not raise_error
    end
  end
end
