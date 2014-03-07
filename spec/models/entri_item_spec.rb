require 'spec_helper'

describe Item::Entri do
  context "relation to fee" do
    let(:item)   { create(:entri_item) }
    let!(:other) { create(:subscripsion_item) }

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

  context "duplicates" do
    let(:bunratty)  { create(:entri_fee, name: "Bunratty") }
    let(:kilkenny)  { create(:entri_fee, name: "Kilkenny") }
    let(:player)    { create(:player) }
    let(:reyalp)    { create(:player) }
    let!(:item1)    { create(:paid_entri_item, fee: bunratty, player: player) }
    let!(:item2)    { create(:paid_entri_item, fee: kilkenny, player: reyalp) }

    it "not for the same player in the same tournament" do
      expect{create(:entri_item, fee: bunratty, player: player)}.to raise_error(/entered/)
      expect{create(:entri_item, fee: kilkenny, player: reyalp)}.to raise_error(/entered/)
    end

    it "different player or tournament" do
      expect{create(:entri_item, fee: bunratty, player: reyalp)}.to_not raise_error
      expect{create(:entri_item, fee: kilkenny, player: player)}.to_not raise_error
    end
  end

  context "inactive duplicates" do
    let(:bunratty)  { create(:entri_fee, name: "Bunratty") }
    let(:kilkenny)  { create(:entri_fee, name: "Kilkenny") }
    let(:player)    { create(:player) }
    let(:reyalp)    { create(:player) }
    let!(:item1)    { create(:entri_item, fee: bunratty, player: player) }
    let!(:item2)    { create(:entri_item, fee: kilkenny, player: reyalp) }

    it "are allowed" do
      expect{create(:entri_item, fee: bunratty, player: player)}.to_not raise_error
      expect{create(:entri_item, fee: kilkenny, player: reyalp)}.to_not raise_error
    end
  end
end
