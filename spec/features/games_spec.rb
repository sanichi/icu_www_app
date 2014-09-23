require 'rails_helper'

describe Game do
  include_context "features"

  let!(:game) { create(:game) }
  let(:user)  { create(:user) }

  let(:download_game)  { I18n.t("game.pgn.download.game") }
  let(:download_games) { I18n.t("game.pgn.download.games") }
  let(:white)          { I18n.t("game.white") }

  context "authorization" do
    let(:level1) { [user] }
    let(:level2) { ["guest"] }

    it "level 1 can download games" do
      level1.each do |role|
        login role
        visit games_path
        click_link download_games
        visit game_path(game)
        click_link download_game
      end
    end

    it "level 2 cannot download games" do
      level2.each do |role|
        login role
        visit games_path
        expect(page).to_not have_link(download_games)
        visit download_games_path
        expect(page).to have_css(failure, text: unauthorized)
        visit game_path(game)
        expect(page).to_not have_link(download_game)
        visit game_path(game, format: "pgn")
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end

  context "download limit" do
    let(:players) { %w[O'Connor,J Carlsen,M] }

    before(:each) do
      players.each { |w| create(:game, white: w) }
      login(user)
    end

    it "over limit" do
      visit games_path
      expect(page).to_not have_link download_games
    end

    it "within limit" do
      visit games_path
      fill_in white, with: players.last
      click_button search
      click_link download_games
    end
  end
end
