require 'rails_helper'

describe Geocodable do
  context Club do
    it "Elm Mount" do
      club = create(:club, address: "Ierne Sport and Leisure Club, Grace Park Road", city: "Dublin", lat: nil, long: nil)
      expect(club.lat).to be_within(0.001).of(53.368)
      expect(club.long).to be_within(0.001).of(-6.249)
    end

    it "Methodist College" do
      club = create(:club, address: "Methodist College", city: "Belfast", lat: nil, long: nil)
      expect(club.lat).to be_within(0.001).of(54.583)
      expect(club.long).to be_within(0.001).of(-5.940)
    end

    it "Unrecognised" do
      club = create(:club, address: "Nowhere Road", city: "Missing City", lat:nil, long: nil)
      expect(club.lat).to be_nil
      expect(club.long).to be_nil
    end
  end

  context Event do
    it "An Oige" do
      event = create(:event, location: "An Oige Youth Club, 61 Mountjoy St, Dublin")
      expect(event.lat).to be_within(0.001).of(53.356)
      expect(event.long).to be_within(0.001).of(-6.268)
    end

    it "Tara Towers" do
      event = create(:event, location: "Tara Towers Hotel, Booterstown")
      expect(event.lat).to be_within(0.001).of(53.312)
      expect(event.long).to be_within(0.001).of(-6.201)
    end

    it "Unrecognised" do
      event = create(:event, location: "Nowhere Road, Missing City")
      expect(event.lat).to be_nil
      expect(event.long).to be_nil
    end
  end
end
