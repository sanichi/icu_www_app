require 'rails_helper'

describe Game do
  let(:game) { create(:game) }

  context "#signature" do
    before(:each) do
      @signature = game.signature
    end

    it "components" do
      expect(game.black).to eq "Orr, M"
      expect(game.date).to eq "1998.07.12"
      expect(game.moves).to match /9\.Qd3/
      expect(game.moves).to match /Qxc3\+/
      expect(game.moves).to match /17\.Kd5/
      expect(game.result).to match "0-1"
      expect(game.white).to eq "Lee, C"
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

  context "#normalize_name" do
    def normalize(name)
      Game.normalize_name(name)
    end

    it "never a space before a comma, always a space after" do
      expect(normalize("Orr  ,M")).to eq "Orr, M"
    end

    it "no periods" do
      expect(normalize("Orr, Mark J. L.")).to eq "Orr, Mark J L"
      expect(normalize("Rynd, J.A.P.")).to eq "Rynd, J A P"
    end

    it "split up initials" do
      expect(normalize("Harvey, EL")).to eq "Harvey, E L"
      expect(normalize("Rynd, JA Porterfield")).to eq "Rynd, J A Porterfield"
      expect(normalize("Rynd,JAPorterfield")).to eq "Rynd, J A Porterfield"
    end

    it "only one way to represent an apostrophe" do
      expect(normalize("O ` Reilly, E")).to eq "O'Reilly, E"
    end

    it "single letter o followed by space" do
      expect(normalize("O Boyle, Una")).to eq "O'Boyle, Una"
      expect(normalize("O  Malley, O E M")).to eq "O'Malley, O E M"
    end

    it "trimmed white space" do
      expect(normalize("  Orr, Mark \t  J L \t")).to eq "Orr, Mark J L"
    end

    it "side effect of validation" do
      g = Game.new(white: " O ′ Fischer , Robert  J . ", black: " O’ Tal  ,   Mikhail  N . ")
      expect(g.valid?).to be false
      expect(g.white).to eq "O'Fischer, Robert J"
      expect(g.black).to eq "O'Tal, Mikhail N"
    end
  end

  context "to_pgn" do
    it "produces valid pgn" do
      pgn_content = <<PGN
[Event "Largs Weekender"]
[Site "?"]
[Date "1998.07.12"]
[Round "4"]
[White "Lee, C"]
[Black "Orr, M"]
[Result "0-1"]
[WhiteElo "2420"]
[ECO "B34"]

1.e4 c5 2.Nf3 Nc6 3.d4 cxd4 4.Nxd4 g6 5.Nc3 Bg7 6.Be3 Nf6 7.f3 O-O 8.Bc4 Qb6
9.Qd3 Ne5 10.Qe2 Qxb2 11.Kd2 Qb4 12.Bd3 Nc6 13.Rab1 Qa5 14.Nb3 Qxc3+ 15.Kxc3
Nxe4+ 16.Kc4 Nd6+ 17.Kd5 Nb4+ 18.Kc5 Bc3 19.Bd4 b6# 0-1
PGN
      expect(game.to_pgn).to eq pgn_content
    end
  end
end
