require 'rails_helper'

describe Officer do
  let(:alice) { "alice@hotmail.com" }
  let(:bob)   { "bob@yahoo.com" }
  let(:mark)  { "mark@gmail.com" }

  let(:fide_ecu) { create(:officer, role: "fide_ecu") }
  let!(:to_fide) { create(:relay, from: "fide@icu.ie", officer: fide_ecu, to: alice) }
  let!(:to_ecu)  { create(:relay, from: "ecu@icu.ie", officer: fide_ecu, to: "#{alice}, #{bob}") }

  let(:ratings)     { create(:officer, role: "ratings") }
  let!(:to_ratings) { create(:relay, from: "ratings@icu.ie", officer: ratings, to: mark) }

  let(:ulster) { create(:officer, role: "ulster") }

  context "emails" do
    context "enabled" do
      it "none" do
        expect(ulster.emails).to be_empty
      end

      it "one" do
        expect(ratings.emails.size).to eq 1
        expect(ratings.emails.first).to eq "ratings@icu.ie"
      end

      it "two" do
        expect(fide_ecu.emails.size).to eq 2
        expect(fide_ecu.emails.first).to eq "ecu@icu.ie"
        expect(fide_ecu.emails.last).to eq "fide@icu.ie"
      end
    end

    context "disabled" do
      before(:each) do
        [to_ecu, to_fide, to_ratings].each do |relay|
          relay.update_column(:enabled, false)
        end
      end

      it "none" do
        expect(ulster.emails).to be_empty
      end

      it "one" do
        expect(ratings.emails.size).to eq 1
        expect(ratings.emails.first).to eq mark
      end

      it "two" do
        expect(fide_ecu.emails.size).to eq 2
        expect(fide_ecu.emails.first).to eq alice
        expect(fide_ecu.emails.last).to eq bob
      end
    end
  end
end
