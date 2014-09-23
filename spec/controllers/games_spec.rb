require 'rails_helper'

describe GamesController do
  context "download games" do
    let!(:game)    { create(:game) }
    let!(:another) { create(:game, white: "O'Connor, J") }
    let(:user)     { create(:user) }

    before(:each) do
      session[:user_id] = user.id
    end

    it "one game" do
      get :show, id: game.id, format: "pgn"
      expect(response).to_not be_redirect
      expect(response.body).to eq game.to_pgn
      expect(response.content_type).to eq "application/x-chess-pgn"
      expect(response.headers["Content-Disposition"]).to match /filename="icu_#{game.id}.pgn"/
    end

    it "multiple games" do
      get :download
      expect(response).to_not be_redirect
      expect(response.body).to eq game.to_pgn + another.to_pgn
      expect(response.content_type).to eq "application/x-chess-pgn"
      expect(response.headers["Content-Disposition"]).to match /filename="icu_search.pgn"/
    end
  end
end
