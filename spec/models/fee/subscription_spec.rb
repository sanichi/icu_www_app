require 'rails_helper'

describe Fee::Subscription do
  let(:fee) { create(:subscription_fee, years: "2013-14", name: "Standard") }

  context "implicitly set attributes" do
    it "sale start and end dates" do
      expect(fee.sale_start.to_s).to eq "2013-08-01"
      expect(fee.sale_end.to_s).to eq "2014-08-31"
      expect(fee.start_date.to_s).to eq "2013-09-01"
      expect(fee.end_date.to_s).to eq "2014-08-31"
    end

    it "age reference date" do
      expect(fee.age_ref_date.to_s).to eq "2014-01-01"
    end

    it "description" do
      expect(fee.description).to eq "2013-14 Standard"
    end
  end

  context "#season" do
    it "years" do
      expect(fee.season.to_s).to eq fee.years
    end

    it "after update" do
      fee.years = fee.season.next.to_s
      fee.save
      expect(fee.season.to_s).to eq fee.years
      expect(fee.start_date).to eq fee.season.start
      expect(fee.age_ref_date).to eq fee.season.end.beginning_of_year
    end
  end

  context "rollover" do
    it "#rolloverable?" do
      expect(fee.rolloverable?).to be true
      create(:subscription_fee, years: fee.season.next.to_s)
      expect(fee.rolloverable?).to be false
    end

    it "#rollover" do
      rof = fee.rollover

      expect(rof.new_record?).to be true
      expect(rof.class).to eq Fee
      expect(rof.name).to eq fee.name
      expect(rof.amount).to eq fee.amount
      expect(rof.years).to eq fee.season.next.to_s
      expect(rof.start_date).to eq fee.start_date.years_since(1)
      expect(rof.end_date).to eq fee.end_date.years_since(1)
      expect(rof.sale_start).to eq fee.sale_start.years_since(1)
      expect(rof.sale_end).to eq fee.sale_end.years_since(1)
      expect(rof.age_ref_date).to eq fee.age_ref_date.years_since(1)
    end
  end

  context "#<=>" do
    let(:std_1)  { create(:subscription_fee, years: "2013-14", name: "Standard") }
    let(:std_2)  { create(:subscription_fee, years: "2014-15", name: "Standard") }
    let(:u18)    { create(:subscription_fee, years: "2013-14", name: "Under 18", amount: 20) }
    let(:u12)    { create(:subscription_fee, years: "2013-14", name: "Under 12", amount: 20) }
    let(:o65_1)  { create(:subscription_fee, years: "2013-14", name: "Over 65", amount: 20) }
    let(:o65_2)  { create(:subscription_fee, years: "2014-15", name: "Over 65", amount: 20) }
    let(:n18)    { create(:subscription_fee, years: "2013-14", name: "New U18", amount: 10) }

    it "season takes precedence" do
      expect(std_2).to be < std_1
      expect(std_2).to be < o65_1
      expect(o65_2).to be < o65_1
      expect(o65_2).to be < std_1
    end

    it "then amount" do
      expect(std_1).to be < o65_1
      expect(std_2).to be < o65_2
      expect(std_1).to be < u18
      expect(std_1).to be < u12
      expect(u18).to be < n18
      expect(u18).to be < n18
    end

    it "then description" do
      expect(o65_1).to be < u18
      expect(u12).to be < u18
    end
  end
end
