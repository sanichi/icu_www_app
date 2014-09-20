require 'rails_helper'

module Util
  describe ChargeProfile do
    let(:profile) { Util::ChargeProfile.new(24, 10000, 0.0001, "EUR") }

    context "cost" do
      it "under" do
        expect(profile.cost(0)).to eq 0.0
        expect(profile.cost(1000)).to eq 0.0
        expect(profile.cost(10000)).to eq 0.0
      end

      it "over" do
        expect(profile.cost(10001)).to eq 0.00 # because result is rounded to 2 decimal places
        expect(profile.cost(10100)).to eq 0.01
        expect(profile.cost(11500)).to eq 0.15
        expect(profile.cost(20000)).to eq 1.00
        expect(profile.cost(110000)).to eq 10.00
      end
    end
  end
end
