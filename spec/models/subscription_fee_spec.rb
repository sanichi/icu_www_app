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

  context "rollover" do
    it "#rolloverable?" do
      expect(fee.rolloverable?).to be_true
      rof = fee.rollover
      expect(fee.rolloverable?).to be_false
    end

    it "#rollover" do
      rof = fee.rollover
      expect(rof.category).to eq fee.category
      expect(rof.amount).to eq fee.amount
      expect(rof.season_desc).to eq fee.season.next
      expect(rof.sale_start).to eq fee.sale_start.years_since(1)
      expect(rof.sale_end).to eq fee.sale_end.years_since(1)
      expect(rof.age_ref_date).to eq fee.age_ref_date.years_since(1)
    end
  end
end
