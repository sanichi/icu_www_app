require 'rails_helper'

describe Season do
  context "parse a season" do
    it "regular valid" do
      s = Season.new("2013-14")
      expect(s.error).to be_nil
      expect(s.to_s).to eq "2013-14"
      expect(s.next.to_s).to eq "2014-15"
      expect(s.last.to_s).to eq "2012-13"
      expect(s.start.to_s).to eq "2013-09-01"
      expect(s.end.to_s).to eq "2014-08-31"
      expect(s.end_of_grace_period.to_s).to eq "2014-12-31"
    end

    it "turn of century valid" do
      s = Season.new("1999-00")
      expect(s.error).to be_nil
      expect(s.to_s).to eq "1999-00"
      expect(s.next.to_s).to eq "2000-01"
      expect(s.last.to_s).to eq "1998-99"
      expect(s.start.to_s).to eq "1999-09-01"
      expect(s.end.to_s).to eq "2000-08-31"
      expect(s.end_of_grace_period.to_s).to eq "2000-12-31"
    end

    it "valid variations" do
      {
        "2013-2014"     => "2013-14",
        "1955/1956"     => "1955-56",
        "1986 to 1987"  => "1986-87",
        "1989 90"       => "1989-90",
        "1999/2000"     => "1999-00",
        " 2013 - 2014 " => "2013-14",
      }.each do |input, desc|
        s = Season.new(input)
        expect(s.error).to be_nil
        expect(s.to_s).to eq desc
      end
    end
  end

  context "infer from a date" do
    it "regular valid" do
      s = Season.new(Date.new(2013, 12, 9))
      expect(s.error).to be_nil
      expect(s.to_s).to eq "2013-14"
      expect(s.start.to_s).to eq "2013-09-01"
      expect(s.end.to_s).to eq "2014-08-31"
      expect(s.end_of_grace_period.to_s).to eq "2014-12-31"
    end

    it "turn of century valid" do
      s = Season.new(Date.new(2000, 1, 1))
      expect(s.error).to be_nil
      expect(s.to_s).to eq "1999-00"
      expect(s.start.to_s).to eq "1999-09-01"
      expect(s.end.to_s).to eq "2000-08-31"
      expect(s.end_of_grace_period.to_s).to eq "2000-12-31"
    end

    it "season boundary" do
      expect(Season.new(Date.new(1955, 8, 31)).to_s).to eq "1954-55"
      expect(Season.new(Date.new(1955, 9,  1)).to_s).to eq "1955-56"
    end
  end

  context "default" do
    it "today" do
      s = Season.new
      expect(s.error).to be_nil
      expect(s.to_s).to match /\A20\d\d-\d\d\z/
      expect(s.start.month).to eq 9
      expect(s.end.month).to eq 8
      expect(s.end_of_grace_period.month).to eq 12
    end
  end
end
