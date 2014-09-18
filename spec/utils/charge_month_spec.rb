require 'rails_helper'

module Util
  describe ChargeMonth do
    let(:month) { Util::ChargeMonth.new(start_day, today: today) }

    context "start day less than today's day" do
      context "regular case" do
        let(:start_day) { 5 }
        let(:today)     { Date.new(1955, 11, 9) }

        it "start and end" do
          expect(month.start_date).to eq Date.new(1955, 11, 5)
          expect(month.end_date).to eq Date.new(1955, 12, 4)
        end

        it "included" do
          expect(month.includes?(month.start_date)).to be true
          expect(month.includes?(month.end_date)).to be true
          expect(month.includes?(month.start_date.days_ago(1))).to be false
          expect(month.includes?(month.end_date.days_since(1))).to be false
          expect(month.includes?(today.to_s)).to be true
        end

        it "days" do
          expect(month.days).to eq 30
        end
      end

      context "corner case" do
        let(:start_day) { 30 }
        let(:today)     { Date.new(1988, 1, 31) }

        it "start and end" do
          expect(month.start_date).to eq Date.new(1988, 1, 30)
          expect(month.end_date).to eq Date.new(1988, 2, 29)
        end

        it "days" do
          expect(month.days).to eq 31
        end
      end
    end

    context "start day more than today's day" do
      context "regular case" do
        let(:start_day) { 24 }
        let(:today)     { Date.new(2014, 9, 10) }

        it "start and end" do
          expect(month.start_date).to eq Date.new(2014, 8, 24)
          expect(month.end_date).to eq Date.new(2014, 9, 23)
        end

        it "included" do
          expect(month.includes?(month.start_date)).to be true
          expect(month.includes?(month.end_date)).to be true
          expect(month.includes?(month.start_date.days_ago(1))).to be false
          expect(month.includes?(month.end_date.days_since(1))).to be false
          expect(month.includes?(today.to_s)).to be true
        end

        it "days" do
          expect(month.days).to eq 31
        end
      end

      context "corner case" do
        let(:start_day) { 30 }
        let(:today)     { Date.new(2015, 2, 28) }

        it "start and end" do
          expect(month.start_date).to eq Date.new(2015, 1, 30)
          expect(month.end_date).to eq Date.new(2015, 2, 28)
        end

        it "days" do
          expect(month.days).to eq 30
        end
      end
    end

    context "predictions" do
      let(:start_day) { 24 }
      let(:today)     { Date.new(2014, 10, 18) }

      it "no data" do
        expect(month.predicted_count).to eq 0
        expect(month.predicted_cost).to eq "0.00 USD"
      end

      it "one datum" do
        month.add_data(month.start_date, 100)
        expect(month.predicted_count).to eq 3000
        expect(month.predicted_cost).to eq "0.00 USD"
      end

      it "two data" do
        month.add_data(month.start_date, 200)
        month.add_data(month.end_date, 200)
        expect(month.predicted_count).to eq 6000
        expect(month.predicted_cost).to eq "0.00 USD"
      end

      it "three data" do
        month.add_data(month.start_date, 500)
        month.add_data(month.end_date, 500)
        month.add_data(today, 500)
        expect(month.predicted_count).to eq 15000
        expect(month.predicted_cost).to eq "2.50 USD"
      end

      it "irrelevant data" do
        month.add_data(month.start_date.days_ago(1), 1000)
        month.add_data(month.end_date.days_since(1), 1000)
        expect(month.predicted_count).to eq 0
        expect(month.predicted_cost).to eq "0.00 USD"
      end
    end
  end
end