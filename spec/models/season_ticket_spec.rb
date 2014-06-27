require 'rails_helper'

describe SeasonTicket do
  context "decode" do

    context "valid" do
      let(:ticket) { SeasonTicket.new("brDK6") }

      it "attributes", if: SeasonTicket.standard_config? do
        expect(ticket.error).to be_nil
        expect(ticket.valid?).to be true
        expect(ticket.icu_id).to eq 87
        expect(ticket.expires_on).to eq "2008-12-31"
        expect(ticket.to_s).to eq "brDK6"
      end
    end

    context "invalid" do
      it "nil" do
        ticket = SeasonTicket.new(nil)
        expect(ticket.error).to match(/invalid/)
        expect(ticket.to_s).to eq ""
      end

      it "blank" do
        ticket = SeasonTicket.new("")
        expect(ticket.error).to match(/invalid/)
        expect(ticket.to_s).to eq ""
      end

      it "wrong" do
        ticket = SeasonTicket.new("AcEgI")
        expect(ticket.error).to match(/invalid/)
        expect(ticket.to_s).to eq "AcEgI"
      end
    end
  end

  context "encoding" do
    context "valid" do
      let(:icu_id) { 10470 }
      let(:expiry) { "2012-12-31" }

      it "attributes", if: SeasonTicket.standard_config? do
        ticket = SeasonTicket.new(icu_id, expiry)
        expect(ticket.error).to be_nil
        expect(ticket.valid?).to be true
        expect(ticket.to_s).to eq "M2kFCFx"
      end
    end

    context "invalid" do
      it "ID" do
        ticket = SeasonTicket.new(0, "2013-12-31")
        expect(ticket.error).to match(/ID/)
        expect(ticket.to_s).to match ""
      end

      it "expiry" do
        ticket = SeasonTicket.new(1, "1999-12-31")
        expect(ticket.error).to match(/expiry/)
        expect(ticket.to_s).to match ""
      end
    end
  end

  context "#valid?" do
    let(:ticket) { SeasonTicket.new(12159, "2010-12-31") }

    it "wrong ID or expired date" do
      expect(ticket.valid?).to be true
      expect(ticket.valid?(12159)).to be true
      expect(ticket.valid?(12159, "2010-06-01")).to be true
      expect(ticket.valid?(12159, "2010-12-31")).to be true
      expect(ticket.valid?(12159, "2011-01-01")).to be false
      expect(ticket.valid?(12160, "2013-11-09")).to be false
    end
  end

  context "flexible input types" do
    let(:ticket) { SeasonTicket.new("12040", Date.new(2011, 12, 31)) }

    it "wrong ID or expired date" do
      expect(ticket.valid?).to be true
      expect(ticket.valid?(12040)).to be true
      expect(ticket.valid?("12040")).to be true
      expect(ticket.valid?(12040, "2011-11-09")).to be true
      expect(ticket.valid?(12040, Date.new(2011, 11, 9))).to be true
      expect(ticket.valid?(12040, Date.new(2011, 12, 31))).to be true
      expect(ticket.valid?(12040, Date.new(2012, 1, 1))).to be false
    end
  end
end
