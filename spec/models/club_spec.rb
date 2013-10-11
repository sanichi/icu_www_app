require 'spec_helper'

describe Club do
  let(:bangor) { FactoryGirl.create(:club) }

  context "latitude and longitude" do
    it "can be blank" do
      bangor.latitude = nil
      bangor.longitude = nil
      expect{ bangor.save! }.to_not raise_error
    end

    it "latitude has upper limit" do
      bangor.latitude = 60
      expect{ bangor.save! }.to raise_error(/latitude must be less than/i)
    end

    it "latitude has lower limit" do
      bangor.latitude = 40
      expect{ bangor.save! }.to raise_error(/latitude must be greater than/i)
    end

    it "longitude has upper limit" do
      bangor.longitude = 10
      expect{ bangor.save! }.to raise_error(/longitude must be less than/i)
    end

    it "longitude has lower limit" do
      bangor.longitude = -20
      expect{ bangor.save! }.to raise_error(/longitude must be greater than/i)
    end

    it "can be saved to 6 decimal places" do
      lat, long = 54.676051, -5.620965
      bangor.latitude = lat
      bangor.longitude = long
      bangor.save!
      bangor.reload
      expect(bangor.latitude).to be_within(0.000001).of(lat)
      expect(bangor.longitude).to be_within(0.000001).of(long)
    end

    it "can be given as strings" do
      lat, long = "54.676051", "-5.620965"
      bangor.latitude = lat
      bangor.longitude = long
      bangor.save!
      bangor.reload
      expect(bangor.latitude).to be_within(0.000001).of(lat.to_f)
      expect(bangor.longitude).to be_within(0.000001).of(long.to_f)
    end
  end

  context "province" do
    let(:bangor) { FactoryGirl.create(:club) }

    it "must not be blank or invalid" do
      [nil, "", "scotand", "Ulster"].each do |province|
        bangor.province = province
        expect{ bangor.save! }.to raise_error(/invalid province/i)
      end
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

  context "province and county" do
    let(:bangor) { FactoryGirl.create(:club) }

    it "should be consistent" do
      bangor.province = "ulster"
      bangor.county = "limerick"
      expect{ bangor.save! }.to raise_error(/Limerick.*Ulster/)
      bangor.county = "down"
      expect{ bangor.save! }.to_not raise_error
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
      club = FactoryGirl.create(:club, active: false, meetings: "", district: " ", address: "\s", contact: "", phone: "", email: "", web: "", latitude: "", longitude: "")      
      expect(club.meetings).to be_nil
      expect(club.district).to be_nil
      expect(club.address).to be_nil
      expect(club.contact).to be_nil
      expect(club.phone).to be_nil
      expect(club.email).to be_nil
      expect(club.web).to be_nil
      expect(club.latitude).to be_nil
      expect(club.longitude).to be_nil
    end
  end
end
