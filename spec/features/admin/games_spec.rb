require 'rails_helper'

describe Game do;
  include_context "features"

  let(:para) { "p" }

  let(:game) { create(:game_with_annotations, pgn: pgn) }
  let(:pgn)  { create(:pgn, user: user) }
  let(:user) { create(:user, roles: "editor") }

  context "authorization" do
    let(:level1) { ["admin", user] }
    let(:level2) { User::ROLES.reject { |r| r == "admin" }.append("guest") }

    it "level 1 can edit games as well as view" do
      level1.each do |role|
        login role
        visit edit_admin_game_path(game)
        expect(page).to_not have_css(failure)
        visit game_path(game)
        expect(page).to have_css(para, text: game.details)
        expect(page).to have_link(edit)
        expect(page).to have_link(delete)
      end
    end

    it "level 2 can only view" do
      level2.each do |role|
        login role
        visit edit_admin_game_path(game)
        expect(page).to have_css(failure, text: unauthorized)
        visit game_path(game)
        expect(page).to have_css(para, text: game.details)
        expect(page).to_not have_link(edit)
        expect(page).to_not have_link(delete)
      end
    end
  end

  context "edit" do
    let(:date)   { I18n.t("date") }
    let(:black)  { I18n.t("game.black") }
    let(:event)  { I18n.t("game.event") }
    let(:moves)  { I18n.t("game.moves") }
    let(:result) { I18n.t("game.result") }
    let(:round)  { I18n.t("game.round") }
    let(:white)  { I18n.t("game.white") }

    let(:plain) { attributes_for(:game) }

    before(:each) do
      login user
      visit game_path(game)
      click_link edit
    end

    it "black" do
      fill_in black, with: "Tal,M."
      click_button save

      expect(page).to have_css(success, text: updated)
      game.reload

      expect(game.black).to eq "Tal, M"
      expect(JournalEntry.games.where(action: "update", by: user.signature, journalable_id: game.id, column: "black").count).to eq 1
      expect(JournalEntry.games.count).to eq 1
    end

    it "date" do
      today = Date.today
      fill_in date, with: today.to_s
      click_button save

      expect(page).to have_css(success, text: updated)
      game.reload

      expect(game.date).to eq "#{today.year}.#{'%02d' % today.month}.#{'%02d' % today.day}"

      click_link edit
      fill_in date, with: "1998"
      click_button save

      expect(page).to have_css(success, text: updated)
      game.reload

      expect(game.date).to eq "1998.??.??"

      click_link edit
      fill_in date, with: " 1998 / 7 "
      click_button save

      expect(page).to have_css(success, text: updated)
      game.reload

      expect(game.date).to eq "1998.07.??"

      expect(JournalEntry.games.where(action: "update", by: user.signature, journalable_id: game.id, column: "date").count).to eq 3
      expect(JournalEntry.games.count).to eq 3
    end

    it "result" do
      draw = "½-½"
      select draw, from: result
      click_button save

      expect(page).to have_css(success, text: updated)
      game.reload

      expect(game.result).to eq draw
      expect(JournalEntry.games.where(action: "update", by: user.signature, journalable_id: game.id, column: "result").count).to eq 1
      expect(JournalEntry.games.count).to eq 1
    end

    it "round" do
      fill_in round, with: " 1.2 "
      click_button save

      expect(page).to have_css(success, text: updated)
      game.reload

      expect(game.round).to eq "1.2"
      expect(JournalEntry.games.where(action: "update", by: user.signature, journalable_id: game.id, column: "round").count).to eq 1
      expect(JournalEntry.games.count).to eq 1
    end

    it "event" do
      fill_in event, with: " ? "
      click_button save

      expect(page).to have_css(success, text: updated)
      game.reload

      expect(game.event).to be_nil
      expect(JournalEntry.games.where(action: "update", by: user.signature, journalable_id: game.id, column: "event").count).to eq 1
      expect(JournalEntry.games.count).to eq 1
    end

    it "moves" do
      fill_in moves, with: plain[:moves]
      click_button save

      expect(page).to have_css(success, text: updated)
      game.reload

      expect(game.moves).to eq plain[:moves]
      expect(JournalEntry.games.where(action: "update", by: user.signature, journalable_id: game.id, column: "moves").count).to eq 1
      expect(JournalEntry.games.count).to eq 1
    end

    it "white" do
      fill_in white, with: "Kasparov,G."
      click_button save

      expect(page).to have_css(success, text: updated)
      game.reload

      expect(game.white).to eq "Kasparov, G"
      expect(JournalEntry.games.where(action: "update", by: user.signature, journalable_id: game.id, column: "white").count).to eq 1
      expect(JournalEntry.games.count).to eq 1
    end
  end

  context "destroy" do
    before(:each) do
      login user
    end

    it "delete" do
      visit game_path(game)
      click_link delete

      expect(page).to have_css(success, text: deleted)

      expect(Game.count).to eq 0
      expect(JournalEntry.games.where(action: "destroy", by: user.signature, journalable_id: game.id).count).to eq 1
    end
  end
end
