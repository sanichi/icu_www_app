require 'spec_helper'

describe SubscriptionFee do

  let(:fee) { create(:subscription_fee, season_desc: "2013-14", category: "standard") }
  
  context "implicitly set attributes" do
    it "sale start and end dates" do
      expect(fee.sale_start.to_s).to eq "2013-08-01"
      expect(fee.sale_end.to_s).to eq "2014-08-31"
    end

    it "age reference date" do
      expect(fee.age_ref_date.to_s).to eq "2013-09-01"
    end

    it "description" do
      expect(fee.description).to eq "2013-14 Standard"
    end
  end

  context "#season" do
    it "description" do
      expect(fee.season.desc).to eq fee.season_desc
    end

    it "after update" do
      fee.season_desc = fee.season.next
      fee.save
      expect(fee.season.desc).to eq fee.season_desc
    end
  end
end
