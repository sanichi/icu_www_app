require 'rails_helper'

describe Pgn do;
  include_context "features"

  let(:import)  { "Import?" }
  let(:pgn_dir) { Rails.root + "spec/files/pgns/" }

  context "authorization" do
    let(:cell)   { "//td[.='#{pgn.file_name}']" }
    let(:level1) { ["admin", user] }
    let(:level2) { ["editor"] }
    let(:level3) { User::ROLES.reject { |r| r == "admin" || r == "editor" }.append("guest") }
    let(:pgn)    { create(:pgn, user: user) }
    let(:user)   { create(:user, roles: "editor") }

    it "some roles can manage PGNs" do
      level1.each do |role|
        login role
        visit admin_pgns_path
        expect(page).to_not have_css(failure)
        visit new_admin_pgn_path
        expect(page).to_not have_css(failure)
        visit edit_admin_pgn_path(pgn)
        expect(page).to_not have_css(failure)
        visit admin_pgn_path(pgn)
        expect(page).to have_xpath(cell)
        expect(page).to have_link(edit)
        expect(page).to have_link(delete)
      end
    end

    it "other editors can only create and view" do
      level2.each do |role|
        login role
        visit admin_pgns_path
        expect(page).to_not have_css(failure)
        visit new_admin_pgn_path
        expect(page).to_not have_css(failure, text: unauthorized)
        visit edit_admin_pgn_path(pgn)
        expect(page).to have_css(failure, text: unauthorized)
        visit admin_pgn_path(pgn)
        expect(page).to_not have_css(failure, text: unauthorized)
        expect(page).to have_xpath(cell)
        expect(page).to_not have_link(edit)
        expect(page).to_not have_link(delete)
      end
    end

    it "other roles cannot even view" do
      level3.each do |role|
        login role
        visit admin_pgns_path
        expect(page).to have_css(failure)
        visit new_admin_pgn_path
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_pgn_path(pgn)
        expect(page).to have_css(failure, text: unauthorized)
        visit admin_pgn_path(pgn)
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end

  context "create" do
    let(:data)     { build(:pgn, comment: "Mark Orr's Best Games", file_name: "mjo.pgn") }
    let(:imported) { "games imported" }
    let(:parsed)   { "parsed successfully" }

    before(:each) do
      @user = login("editor")
      visit new_admin_pgn_path
    end

    it "check" do
      attach_file file, pgn_dir + data.file_name
      fill_in comment, with: data.comment
      click_button save
      expect(page).to have_css(warning, text: parsed)

      expect(Pgn.count).to eq 1
      pgn = Pgn.first

      expect(pgn.comment).to eq data.comment
      expect(pgn.content_type).to eq "text/plain"
      expect(pgn.duplicates).to eq 0
      expect(pgn.file_name).to eq data.file_name
      expect(pgn.file_size).to eq 242697
      expect(pgn.game_count).to eq 268
      expect(pgn.imports).to eq 0
      expect(pgn.lines).to eq 5972
      expect(pgn.problem).to be_nil
      expect(pgn.user_id).to eq @user.id

      expect(Game.count).to eq 0
      expect(JournalEntry.pgns.where(action: "create", by: @user.signature, journalable_id: pgn.id).count).to eq 1
    end

    it "import" do
      attach_file file, pgn_dir + data.file_name
      check import
      click_button save
      expect(page).to have_css(success, text: imported)

      expect(Pgn.count).to eq 1
      pgn = Pgn.first

      expect(pgn.comment).to be_nil
      expect(pgn.content_type).to eq "text/plain"
      expect(pgn.duplicates).to eq 1
      expect(pgn.file_name).to eq data.file_name
      expect(pgn.file_size).to eq 242697
      expect(pgn.game_count).to eq 268
      expect(pgn.imports).to eq 267
      expect(pgn.lines).to eq 5972
      expect(pgn.problem).to be_nil
      expect(pgn.user_id).to eq @user.id

      expect(Game.count).to eq 267
      expect(JournalEntry.pgns.where(action: "create", by: @user.signature, journalable_id: pgn.id).count).to eq 1
    end
  end

  context "edit" do
    let(:data) { build(:pgn, comment: "I like to comment") }

    before(:each) do
      @user = login "editor"
      visit new_admin_pgn_path
      attach_file file, pgn_dir + "best.pgn"
      check import
      click_button save
    end

    it "comment" do
      expect(Pgn.count).to eq 1
      pgn = Pgn.first
      expect(pgn.comment).to be_nil

      click_link edit
      fill_in comment, with: data.comment
      click_button save

      expect(page).to have_css(success, text: updated)

      pgn.reload
      expect(pgn.comment).to eq data.comment

      expect(JournalEntry.pgns.where(action: "update", by: @user.signature, journalable_id: pgn.id, column: "comment").count).to eq 1
    end
  end

  context "delete" do
    before(:each) do
      @user = login "editor"
      visit new_admin_pgn_path
      attach_file file, pgn_dir + "best.pgn"
      check import
      click_button save
    end

    it "with games" do
      expect(Pgn.count).to eq 1
      expect(Game.count).to eq 44

      click_link delete
      expect(page).to have_css(success, text: deleted)

      expect(Pgn.count).to eq 0
      expect(Game.count).to be 0
      expect(JournalEntry.pgns.where(action: "destroy", by: @user.signature).count).to eq 1
    end
  end
end
