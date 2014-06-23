require 'rails_helper'

describe Board do
  context "validation" do
    it "initial position" do
      expect{Board.new("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w")}.to_not raise_error
    end

    it "invalid syntax" do
      expect{Board.new("-")}.to raise_error(/position/)
      expect{Board.new("pppppppp/rnbqkbnr/8/8/8/8/PPPPPPPP/RNBQKBNR w")}.to raise_error(/position/)
      expect{Board.new("rnbqkbnr/pppppppp/8/8/8/8/RNBQKBNR/PPPPPPPP w")}.to raise_error(/position/)
    end

    it "invalid row" do
      expect{Board.new("r6/ppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w")}.to raise_error(/invalid board row \(r6\)/)
      expect{Board.new("rnbqkbnr/4p4/8/8/8/8/PPPPPPPP/RNBQKBNR w")}.to raise_error(/invalid board row \(4p4\)/)
    end
  end

  context "#to_move" do
    it "implicit start position" do
      board = Board.new
      expect(board.to_move).to eq "w"
    end

    it "explicit start position" do
      board = Board.new("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w")
      expect(board.to_move).to eq "w"
    end

    it "custom position" do
      board = Board.new("K7/8/8/8/8/8/8/7k b")
      expect(board.to_move).to eq "b"
    end
  end

  context "styles" do
    Board::STYLES.each do |style|
      it "#{style} is valid" do
        expect(style).to match Board::VALID_STYLE
      end
    end
  end
end
