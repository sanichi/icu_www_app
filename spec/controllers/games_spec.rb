require 'rails_helper'

describe GamesController do
  context "download pgn file" do
    before(:each) do
      @game1 = create(:game)
      @game2 = create(:game_with_annotations, white: 'Me')
    end

    it "produces pgn output" do
      get "index", format: 'pgn'
      expect(response).to_not be_redirect
      puts response.inspect
      expect(response.content_type).to eq "application/x-chess-pgn"
      expect(response.headers['Content-Disposition']).to include('filename="icu.pgn"')
    end
  end
end
