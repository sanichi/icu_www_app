require 'spec_helper'

describe NewPlayer do
  let(:blank) { NewPlayer.new }
  let(:valid) { NewPlayer.new(attributes_for(:new_player)) }

  # Adapted from https://github.com/rails/rails/blob/master/activemodel/lib/active_model/lint.rb.
  context "lint" do
    let(:model_name) { NewPlayer.model_name }

    it "instance methods" do
      expect(blank.to_key).to be_nil
      expect(blank.to_param).to be_nil
      expect(blank.to_partial_path).to eq "new_players/new_player"
    end

    it "model name" do
      expect(model_name.to_str).to eq "NewPlayer"
      expect(model_name.human.to_str).to eq "New player"
      expect(model_name.singular.to_str).to eq "new_player"
      expect(model_name.plural.to_str).to eq "new_players"
    end
  end

  context "validation" do
    it "blank" do
      expect(blank).to_not be_valid
      errors = blank.errors
      [:first_name, :last_name, :dob, :gender, :joined, :fed].each do |atr|
       expect(errors[atr]).to be_present
      end
    end

    it "factory" do
      expect(valid).to be_valid
    end
  end

  context "#to_json" do
    it "length" do
      json = valid.to_json
      expect(json.length).to be < 256
    end

    it "values" do
      expect(valid).to be_valid
      hash = JSON.parse(valid.to_json)
      NewPlayer::ATTRS.each do |atr|
        expect(hash[atr.to_s].to_s).to eq valid.send(atr).to_s
      end
      expect(hash.size).to eq NewPlayer::ATTRS.size
    end
  end

  context "#from_json" do
    it "valid" do
      new_player = NewPlayer.from_json(valid.to_json)
      expect(new_player).to be_a NewPlayer
      NewPlayer::ATTRS.each do |atr|
        expect(new_player.send(atr)).to eq valid.send(atr)
      end
    end

    it "rubbish" do
      expect(NewPlayer.from_json('{"rubbish":"more rubbish"}')).to be_nil
      expect(NewPlayer.from_json("rubbish")).to be_nil
      expect(NewPlayer.from_json("")).to be_nil
      expect(NewPlayer.from_json(nil)).to be_nil
    end
  end

  context "canonicalisation" do
    let(:untidy) { NewPlayer.new(attributes_for(:new_player, first_name: " marK ", last_name: " lowRy - O rEillY  ", email: " ", club_id: "")) }

    it "name" do
      expect(untidy.first_name).to eq "Mark"
      expect(untidy.last_name).to eq "Lowry-O'Reilly"
    end

    it "email" do
      expect(untidy.email).to be_nil
    end

    it "club" do
      expect(untidy.club_id).to be_nil
    end
  end

  context "to_player" do
    it "valid" do
      player = valid.to_player
      expect(player).to be_a Player
      expect(player).to be_valid
    end

    it "blank" do
      player = blank.to_player
      expect(player).to be_a Player
      expect(player).to_not be_valid
    end
  end

  context "#no_duplicates" do
    let!(:player)    { create(:player) }
    let!(:db_dup)    { create(:player, player_id: player.id) }
    let(:new_player) { build(:new_player) }
    let(:duplicate)  { build(:new_player, first_name: player.first_name, last_name: player.last_name, dob: player.dob) }
    let(:not_a_dup)  { build(:new_player, first_name: db_dup.first_name, last_name: db_dup.last_name, dob: db_dup.dob) }

    it "non-duplicate" do
      expect(new_player).to be_valid
      expect(new_player.errors[:base]).to be_empty
    end

    it "duplicate" do
      expect(duplicate).to_not be_valid
      expect(duplicate.errors[:base]).to_not be_empty
      expect(duplicate.errors[:base].first).to include player.name(id: true)
    end

    it "database duplicate" do
      expect(not_a_dup).to be_valid
      expect(not_a_dup.errors[:base]).to be_empty
    end
  end

  context "#==" do
    let(:player)  { build(:new_player) }
    let(:player1) { build(:new_player, first_name: player.first_name, last_name: player.last_name, dob: player.dob) }
    let(:player2) { build(:new_player, first_name: player.first_name + " X.", last_name: player.last_name, dob: player.dob) }
    let(:player3) { build(:new_player, first_name: player.first_name, last_name: player.last_name, dob: player.dob, gender: player.gender == "M" ? "F" : "M") }
    let(:player4) { build(:new_player, first_name: player.first_name, last_name: player.last_name, dob: player.dob.years_ago(1)) }
    let(:player5) { build(:new_player, first_name: player.first_name, last_name: player.last_name + "son", dob: player.dob) }

    it "equal" do
      expect(player1 == player).to eq true
      expect(player2 == player).to eq true
      expect(player3 == player).to eq true
    end

    it "not equal" do
      expect(player4 == player).to eq false
      expect(player5 == player).to eq false
      expect(player5 == nil).to eq false
    end
  end
end
