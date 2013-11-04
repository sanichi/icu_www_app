require 'spec_helper'

describe Player do
  context "normalisation" do
    it "name" do
      player = FactoryGirl.create(:player, first_name: " MARK j L ", last_name: " O ToolE ")
      expect(player.first_name).to eq "Mark J. L."
      expect(player.last_name).to eq "O'Toole"
    end

    it "player_id, gender, dob, joined" do
      player = FactoryGirl.create(:player, player_id: "", gender: "", dob: "", joined: "", status: "active", source: "import")
      expect(player.player_id).to be_nil
      expect(player.gender).to be_nil
      expect(player.dob).to be_nil
      expect(player.joined).to be_nil
    end
  end

  context "conditional validation" do
    let(:params) { FactoryGirl.attributes_for(:player) }
    let(:master) { FactoryGirl.create(:player) }

    it "factory defaults" do
      expect{Player.create!(params)}.to_not raise_error
    end

    it "dob" do
      expect{Player.create!(params.merge(dob: nil))}.to raise_error(/blank/)
      expect{Player.create!(params.merge(dob: nil, status: "inactive"))}.to_not raise_error
      expect{Player.create!(params.merge(dob: nil, source: "import"))}.to_not raise_error
      expect{Player.create!(params.merge(dob: nil, source: "archive"))}.to_not raise_error
      expect{Player.create!(params.merge(dob: nil, player_id: master.id))}.to_not raise_error
    end

    it "joined" do
      expect{Player.create!(params.merge(joined: nil))}.to raise_error(/blank/)
      expect{Player.create!(params.merge(joined: nil, status: "inactive"))}.to_not raise_error
      expect{Player.create!(params.merge(joined: nil, source: "import"))}.to_not raise_error
      expect{Player.create!(params.merge(joined: nil, source: "archive"))}.to_not raise_error
      expect{Player.create!(params.merge(joined: nil, player_id: master.id))}.to_not raise_error
    end

    it "gender" do
      expect{Player.create!(params.merge(gender: nil))}.to raise_error(/blank/)
      expect{Player.create!(params.merge(gender: nil, status: "inactive"))}.to_not raise_error
      expect{Player.create!(params.merge(gender: nil, source: "import"))}.to_not raise_error
      expect{Player.create!(params.merge(gender: nil, source: "archive"))}.to_not raise_error
      expect{Player.create!(params.merge(gender: nil, player_id: master.id))}.to_not raise_error
      expect{Player.create!(params.merge(gender: "M"))}.to_not raise_error
      expect{Player.create!(params.merge(gender: "F"))}.to_not raise_error
      expect{Player.create!(params.merge(gender: "W"))}.to raise_error(/invalid/)
    end
  end

  context "conditional adjustment" do
    let(:params) { FactoryGirl.attributes_for(:player) }
    let(:master) { FactoryGirl.create(:player) }

    it "status" do
      player = Player.create!(params.merge(player_id: master.id, status: "active", source: "officer"))
      expect(player.status).to eq "inactive"
    end
  end

  context "extra methods" do
    it "#age" do
      player = FactoryGirl.create(:player, dob: Date.new(1955, 11, 9))
      expect(player.age(Date.new(2013, 11, 8))).to eq 57
      expect(player.age(Date.new(2013, 11, 9))).to eq 58
      player = FactoryGirl.create(:player, dob: Date.new(1956, 2, 29))
      expect(player.age(Date.new(2013, 2, 28))).to eq 56
      expect(player.age(Date.new(2013, 3,  1))).to eq 57
      expect(player.age(Date.new(2012, 2, 28))).to eq 55
      expect(player.age(Date.new(2012, 2, 29))).to eq 56
      expect(player.age(Date.new(2012, 3,  1))).to eq 56
    end

    it "#federation" do
      player = FactoryGirl.create(:player, fed: "IRL")
      expect(player.federation).to eq "Ireland"
      expect(player.federation(true)).to eq "Ireland (IRL)"
      player = FactoryGirl.create(:player, fed: nil)
      expect(player.federation).to be_nil
      expect(player.federation(true)).to be_nil
      player.update_column(:fed, "XYZ")
      expect(player.federation).to eq "Unknown"
      expect(player.federation(true)).to eq "Unknown (XYZ)"
    end
  end
end
