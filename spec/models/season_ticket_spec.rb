require 'rails_helper'

describe SeasonTicket do
  context "decode" do
    let(:ticket) { SeasonTicket.new("brDK6") }

    it "ICU ID and expiry date", if: SeasonTicket.standard_config? do
      expect(ticket.error).to be_nil
      expect(ticket.valid?).to be true
      expect(ticket.icu_id).to eq 87
      expect(ticket.expires_on).to eq "2008-12-31"
    end

    it "invalid" do
      expect(SeasonTicket.new(nil).error).to match(/invalid/)
      expect(SeasonTicket.new("").error).to match(/invalid/)
      expect(SeasonTicket.new("AcEgI").error).to match(/invalid/)
    end
  end

  context "encoding" do
    let(:icu_id) { 10470 }
    let(:expiry) { "2012-12-31" }

    it "valid", if: SeasonTicket.standard_config? do
      ticket = SeasonTicket.new(icu_id, expiry)
      expect(ticket.error).to be_nil
      expect(ticket.valid?).to be true
      expect(ticket.ticket).to eq "M2kFCFx"
    end

    it "invalid" do
      expect(SeasonTicket.new(0, "2013-12-31").error).to match(/ID/)
      expect(SeasonTicket.new(1, "1999-12-31").error).to match(/expiry/)
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
