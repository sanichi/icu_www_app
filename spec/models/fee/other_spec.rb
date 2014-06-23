require 'rails_helper'

describe Fee::Other do
  context "days" do
    let(:days)      { 10 }
    let(:today)     { Date.today }
    let(:next_year) { Date.today.years_since(1) }

    it "with neither date" do
      fee = create(:other_fee, days: days.to_s)
      expect(fee.start_date).to be_nil
      expect(fee.end_date).to be_nil
      expect(fee.days).to eq days
    end

    it "with start date" do
      fee = create(:other_fee, start_date: today.to_s, days: days.to_s)
      expect(fee.start_date).to eq today
      expect(fee.end_date).to eq today.days_since(days)
      expect(fee.days).to be_nil
    end

    it "with end date" do
      fee = create(:other_fee, end_date: today.to_s, days: days.to_s)
      expect(fee.start_date).to eq today.days_ago(days)
      expect(fee.end_date).to eq today
      expect(fee.days).to be_nil
    end

    it "with both dates" do
      fee = create(:other_fee, start_date: today.to_s, end_date: next_year.to_s)
      expect(fee.start_date).to eq today
      expect(fee.end_date).to eq next_year
      expect(fee.days).to be_nil
    end

    it "without days or dates" do
      fee = create(:other_fee)
      expect(fee.start_date).to be_nil
      expect(fee.end_date).to be_nil
      expect(fee.days).to be_nil
    end
  end
end
