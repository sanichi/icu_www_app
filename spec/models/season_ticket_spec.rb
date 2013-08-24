require 'spec_helper'

describe SeasonTicket do
  context "decode a ticket" do
    it "should result in correct ICU ID and expiry date" do
      @t = SeasonTicket.new("brDK6")
      @t.error.should be_nil
      @t.valid?.should be_true
      @t.icu_id.should == 87
      @t.expires_on.should == "2008-12-31"
    end

    it "should detect an invalid ticket" do
       SeasonTicket.new(nil).error.should match(/invalid/)
       SeasonTicket.new("").error.should match(/invalid/)
       SeasonTicket.new("AcEgI").error.should match(/invalid/)
    end
  end

  context "encoding an ID and date" do
    it "should result in a correct ticket" do
      @t = SeasonTicket.new(10470, "2012-12-31")
      @t.error.should be_nil
      @t.valid?.should be_true
      @t.ticket.should == "M2kFCFx"
    end

    it "should detect invalid ICU ID or expiry date" do
      SeasonTicket.new(0, "2013-12-31").error.should match(/ID/)
      SeasonTicket.new(1, "1999-12-31").error.should match(/expiry/)
    end
  end

  context "#valid?" do
    before(:each) do
      @t = SeasonTicket.new(12159, "2010-12-31")
    end

    it "should reject wrong ID or date that is after the expiry" do
      @t.valid?.should be_true
      @t.valid?(12159).should be_true
      @t.valid?(12159, "2010-06-01").should be_true
      @t.valid?(12159, "2010-12-31").should be_true
      @t.valid?(12159, "2011-01-01").should be_false
      @t.valid?(12160, "2013-11-09").should be_false
    end
  end

  context "flexible input types" do
    before(:each) do
      @t = SeasonTicket.new("12040", Date.new(2011, 12, 31))
    end

    it "should reject wrong ID or expired date" do
      @t.valid?.should be_true
      @t.valid?(12040).should be_true
      @t.valid?("12040").should be_true
      @t.valid?(12040, "2011-11-09").should be_true
      @t.valid?(12040, Date.new(2011, 11, 9)).should be_true
      @t.valid?(12040, Date.new(2011, 12, 31)).should be_true
      @t.valid?(12040, Date.new(2012, 1, 1)).should be_false
    end
  end
end
