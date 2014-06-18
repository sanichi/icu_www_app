require 'spec_helper'

describe Player do
  context "normalisation" do
    it "name" do
      player = create(:player, first_name: " MARK j L ", last_name: " O ToolE ")
      expect(player.first_name).to eq "Mark J. L."
      expect(player.last_name).to eq "O'Toole"
    end

    it "player_id, gender, dob, joined" do
      player = create(:player, player_id: "", gender: "", dob: "", joined: "", status: "active", source: "import")
      expect(player.player_id).to be_nil
      expect(player.gender).to be_nil
      expect(player.dob).to be_nil
      expect(player.joined).to be_nil
    end
  end

  context "conditional validation" do
    let(:params) { FactoryGirl.attributes_for(:player) }
    let(:master) { create(:player) }

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

    it "legacy ratings" do
      expect{Player.create!(params.merge(legacy_rating: 2000, legacy_rating_type: "full", legacy_games: 10))}.to_not raise_error
      expect{Player.create!(params.merge(legacy_rating: nil, legacy_rating_type: nil, legacy_games: nil))}.to_not raise_error
      expect{Player.create!(params.merge(legacy_rating: 1000, legacy_rating_type: nil, legacy_games: nil))}.to raise_error(/all.*none/)
      expect{Player.create!(params.merge(legacy_rating: nil, legacy_rating_type: "provisional", legacy_games: nil))}.to raise_error(/all.*none/)
      expect{Player.create!(params.merge(legacy_rating: nil, legacy_rating_type: nil, legacy_games: 0))}.to raise_error(/all.*none/)
    end
  end

  context "conditional adjustment" do
    let(:params) { FactoryGirl.attributes_for(:player) }
    let(:master) { create(:player) }

    it "status" do
      player = Player.create!(params.merge(player_id: master.id, status: "active", source: "officer"))
      expect(player.status).to eq "inactive"
    end
  end

  context "phones" do
    let(:params) { FactoryGirl.attributes_for(:player) }
    let(:master) { create(:player) }

    it "mobile correction" do
      player = create(:player, home_phone: "087 123 4567", mobile_phone: "01 456 7890")
      expect(player.home_phone).to eq "01 4567890"
      expect(player.mobile_phone).to eq "087 1234567"
      player = create(:player, home_phone: "087 123 4567")
      expect(player.home_phone).to be_nil
      expect(player.mobile_phone).to eq "087 1234567"
    end
  end

  context "extra methods" do
    it "#age" do
      player = create(:player, dob: Date.new(1955, 11, 9))
      expect(player.age(Date.new(2013, 11, 8))).to eq 57
      expect(player.age(Date.new(2013, 11, 9))).to eq 58
      player = create(:player, dob: Date.new(1956, 2, 29))
      expect(player.age(Date.new(2013, 2, 28))).to eq 56
      expect(player.age(Date.new(2013, 3,  1))).to eq 57
      expect(player.age(Date.new(2012, 2, 28))).to eq 55
      expect(player.age(Date.new(2012, 2, 29))).to eq 56
      expect(player.age(Date.new(2012, 3,  1))).to eq 56
    end

    it "#federation" do
      player = create(:player, fed: "IRL")
      expect(player.federation).to eq "Ireland"
      expect(player.federation(true)).to eq "Ireland (IRL)"
      player = create(:player, fed: nil)
      expect(player.federation).to be_nil
      expect(player.federation(true)).to be_nil
      player.update_column(:fed, "XYZ")
      expect(player.federation).to eq "Unknown"
      expect(player.federation(true)).to eq "Unknown (XYZ)"
    end

    it "#phones" do
      player = create(:player, home_phone: "+44 131 553 9051", mobile_phone: "0044 7968 537010")
      expect(player.phones).to eq "h: 0044 131 5539051, m: 0044 7968 537010"
      player = create(:player, home_phone: "01 8304991", mobile_phone: "086 854 0597", work_phone: "01-6477406")
      expect(player.phones).to eq "h: 01 8304991, m: 086 8540597, w: 01 6477406"
      player = create(:player)
      expect(player.phones).to eq ""
    end

    it "#name" do
      player = create(:player, first_name: "Mark", last_name: "Orr")
      expect(player.name).to eq "Mark Orr"
      expect(player.name(reversed: true)).to eq "Orr, Mark"
      expect(player.name(id: true)).to eq "Mark Orr (#{player.id})"
      expect(player.name(reversed: true, id: true)).to eq "Orr, Mark (#{player.id})"
      player = build(:player, first_name: "Mark", last_name: "Orr")
      expect(player.name(id: true)).to eq "Mark Orr (#{I18n.t('new')})"
    end

    it "#initials" do
      expect(create(:player, first_name: "Mark", last_name: "Orr").initials).to eq "MO"
      expect(create(:player, first_name: "jonathan", last_name: "o'connor").initials).to eq "JOC"
      expect(create(:player, first_name: "Úna", last_name: "O'Boyle").initials).to eq "UOB"
    end
  end
end
