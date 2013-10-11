require 'spec_helper'

describe Club do
  let(:bangor) { FactoryGirl.create(:club) }

  context "latitude and longitude" do
    it "can be blank" do
      bangor.lat = nil
      bangor.long = nil
      expect{ bangor.save! }.to_not raise_error
    end

    it "latitude has upper limit" do
      bangor.lat = 60
      expect{ bangor.save! }.to raise_error(/must be between/i)
    end

    it "latitude has lower limit" do
      bangor.lat = 40
      expect{ bangor.save! }.to raise_error(/must be between/i)
    end

    it "longitude has upper limit" do
      bangor.long = 10
      expect{ bangor.save! }.to raise_error(/must be between/i)
    end

    it "longitude has lower limit" do
      bangor.long = -20
      expect{ bangor.save! }.to raise_error(/must be between/i)
    end

    it "can be saved to 6 decimal places" do
      lat, long = 54.676051, -5.620965
      bangor.lat = lat
      bangor.long = long
      bangor.save!
      bangor.reload
      expect(bangor.lat).to be_within(0.000001).of(lat)
      expect(bangor.long).to be_within(0.000001).of(long)
    end

    it "can be given as strings" do
      lat, long = "54.676051", "-5.620965"
      bangor.lat = lat
      bangor.long = long
      bangor.save!
      bangor.reload
      expect(bangor.lat).to be_within(0.000001).of(lat.to_f)
      expect(bangor.long).to be_within(0.000001).of(long.to_f)
    end
  end

  context "county" do
    let(:bangor) { FactoryGirl.create(:club) }

    it "must not be blank or invalid" do
      [nil, "", "somerset", "Down"].each do |county|
        bangor.county = county
        expect{ bangor.save! }.to raise_error(/invalid county/i)
      end
    end
  end

  context "web" do
    let(:bangor) { FactoryGirl.create(:club) }

    it "can be blank" do
      bangor.web = nil
      expect{ bangor.save! }.to_not raise_error
    end

    it "should be a full URL" do
      bangor.web = "mailto:joe@example.club.com"
      expect{ bangor.save! }.to raise_error(/invalid/)
      bangor.web = "http://example.club.com"
      expect{ bangor.save! }.to_not raise_error
    end

    it "partial URLs can be repaired" do
      bangor.web = "example.club.com/home"
      expect{ bangor.save! }.to_not raise_error
      bangor.reload
      expect(bangor.web).to eq "http://example.club.com/home"
    end
  end

  context "blank attributes" do
    it "are normalised" do
      club = FactoryGirl.create(:club, web: "", meet: "", address: "\s", district: " ", lat: "", long: "", contact: "", email: "", phone: "", active: false)
      expect(club.meet).to be_nil
      expect(club.district).to be_nil
      expect(club.address).to be_nil
      expect(club.contact).to be_nil
      expect(club.phone).to be_nil
      expect(club.email).to be_nil
      expect(club.web).to be_nil
      expect(club.lat).to be_nil
      expect(club.long).to be_nil
    end
  end
end
