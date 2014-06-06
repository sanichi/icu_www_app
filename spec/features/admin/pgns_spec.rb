require 'spec_helper'

describe Pgn do
  let(:comment_input) { I18n.t("comment") }
  let(:delete)        { I18n.t("delete") }
  let(:edit)          { I18n.t("edit") }
  let(:file)          { I18n.t("file") }
  let(:save)          { I18n.t("save") }

  let(:import) { "Import?" }

  let(:failure) { "div.alert-danger" }
  let(:success) { "div.alert-success" }
  let(:warning) { "div.alert-warning" }

  let(:pgn_dir) { Rails.root + "spec/files/pgns/" }

  context "authorization" do
    let(:cell)         { "//td[.='#{pgn.file_name}']" }
    let(:level1)       { ["admin", user] }
    let(:level2)       { ["editor"] }
    let(:level3)       { User::ROLES.reject { |r| r == "admin" || r == "editor" }.append("guest") }
    let(:pgn)          { create(:pgn, user: user) }
    let(:user)         { create(:user, roles: "editor") }
    let(:unauthorized) { I18n.t("errors.alerts.unauthorized") }

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
    let(:comment)   { "Mark Orr's Best Games" }
    let(:file_name) { "mjo.pgn" }
    let(:imported)  { "games imported" }
    let(:parsed)    { "parsed successfully" }

    before(:each) do
      @user = login("editor")
      visit new_admin_pgn_path
    end

    it "check" do
      attach_file file, pgn_dir + file_name
      fill_in comment_input, with: comment
      click_button save
      expect(page).to have_css(warning, text: parsed)

      expect(Pgn.count).to eq 1
      pgn = Pgn.first

      expect(pgn.comment).to eq comment
      expect(pgn.content_type).to eq "text/plain"
      expect(pgn.duplicates).to eq 0
      expect(pgn.file_name).to eq file_name
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
      attach_file file, pgn_dir + file_name
      check import
      click_button save
      expect(page).to have_css(success, text: imported)

      expect(Pgn.count).to eq 1
      pgn = Pgn.first

      expect(pgn.comment).to be_nil
      expect(pgn.content_type).to eq "text/plain"
      expect(pgn.duplicates).to eq 1
      expect(pgn.file_name).to eq file_name
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
    let(:comment) { "I like to comment" }
    let(:updated) { "successfully updated" }

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
      fill_in comment_input, with: comment
      click_button save

      expect(page).to have_css(success, text: updated)

      pgn.reload
      expect(pgn.comment).to eq comment

      expect(JournalEntry.pgns.where(action: "update", by: @user.signature, journalable_id: pgn.id, column: "comment").count).to eq 1
    end
  end

  context "delete" do
    let(:deleted) { "successfully deleted" }

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
