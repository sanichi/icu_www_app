require 'spec_helper'

describe Game do
  context "#signature" do
    let(:game) { create(:game) }

    before(:each) do
      @signature = game.signature
    end

    it "components" do
      expect(game.black).to eq "Orr,M"
      expect(game.date).to eq "1998.07.12"
      expect(game.moves).to match /9\.Qd3/
      expect(game.moves).to match /Qxc3\+/
      expect(game.moves).to match /17\.Kd5/
      expect(game.result).to match "0-1"
      expect(game.white).to eq "Lee,C"
    end

    it "comments are ignored" do
      game.moves.sub!(/9\.Qd3/, "9.Qd3 { A panic reaction. }")
      expect(game.send(:sign)).to eq @signature
    end

    it "date is significant" do
      game.date = "1998.??.??"
      expect(game.send(:sign)).to_not eq @signature
    end

    it "moves are significant" do
      game.moves.sub!(/17\.Kd5/, "17.Kc5")
      expect(game.send(:sign)).to_not eq @signature
    end

    it "last names are significant, first names are ignored" do
      game.black = "Orr, M"
      expect(game.send(:sign)).to eq @signature
      game.white = "Lee, C."
      expect(game.send(:sign)).to eq @signature
      game.black = "orr,mark"
      expect(game.send(:sign)).to eq @signature
      game.black = "Tal,M"
      expect(game.send(:sign)).to_not eq @signature
    end

    it "result is significant" do
      game.result = "1-0"
      expect(game.send(:sign)).to_not eq @signature
    end

    it "symbols are ignored" do
      game.moves.sub!(/Qxc3\+/, "Qxc3+!!")
      expect(game.send(:sign)).to eq @signature
      game.moves.sub!(/9\.Qd3/, "9.Qd3 $2")
      expect(game.send(:sign)).to eq @signature
    end

    it "variations are ignored" do
      game.moves.sub!(/17\.Kd5/, "17.Kd5 ( 17.Kc5 b6+ 18.Kd5 Nb4# )")
      expect(game.send(:sign)).to eq @signature
    end
  end
end
