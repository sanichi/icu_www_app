require 'rails_helper'

describe Champion do
  include_context "features"

  let(:winners) { I18n.t("champion.winners") }

  let(:cell)      { "td" }
  let(:dup_error) { "one category per year" }

  context "authorization" do
    let(:level1)   { %w[admin editor] }
    let(:level2)   { User::ROLES.reject { |role| level1.include?(role) }.append("guest") }
    let(:champion) { create(:champion) }

    it "level1 can manage champions" do
      level1.each do |role|
        login role
        visit new_admin_champion_path
        expect(page).to_not have_css(failure)
        visit edit_admin_champion_path(champion)
        expect(page).to_not have_css(failure)
        visit champion_path(champion)
        expect(page).to have_css(cell, text: champion.winners)
        expect(page).to have_link(edit)
        expect(page).to have_link(delete)
      end
    end

    it "level2 can only view" do
      level2.each do |role|
        login role
        visit new_admin_champion_path
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_champion_path(champion)
        expect(page).to have_css(failure, text: unauthorized)
        visit champion_path(champion)
        expect(page).to have_css(cell, text: champion.winners)
        expect(page).to_not have_link(edit)
        expect(page).to_not have_link(delete)
      end
    end
  end

  context "create" do
    let(:data) { build(:champion, notes: "I remember it well") }

    before(:each) do
      @user = login("editor")
      visit new_admin_champion_path
      fill_in year, with: data.year
      fill_in winners, with: data.winners
      select I18n.t("champion.category.#{data.category}"), from: category
    end

    it "with notes" do
      fill_in notes, with: data.notes
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Champion.count).to eq 1
      champion = Champion.first

      expect(champion.category).to eq data.category
      expect(champion.notes).to eq data.notes
      expect(champion.winners).to eq data.winners
      expect(champion.year).to eq data.year

      expect(JournalEntry.champions.where(action: "create", by: @user.signature, journalable_id: champion.id).count).to eq 1
    end

    it "without notes" do
      fill_in notes, with: "  "
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Champion.count).to eq 1
      champion = Champion.first

      expect(champion.category).to eq data.category
      expect(champion.notes).to be_nil
      expect(champion.winners).to eq data.winners
      expect(champion.year).to eq data.year

      expect(JournalEntry.champions.where(action: "create", by: @user.signature, journalable_id: champion.id).count).to eq 1
    end

    it "duplicate" do
      create(:champion)
      click_button save

      expect(page).to_not have_css(success)
      expect(page).to have_css(field_error, text: dup_error)
      expect(Champion.count).to eq 1

      fill_in year, with: data.year + 1
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Champion.count).to eq 2
      expect(Champion.first.year).to eq data.year
      expect(Champion.last.year).to eq data.year + 1
    end
  end

  context "edit" do
    let(:champion) { create(:champion) }
    let(:data)     { build(:champion, year: 1980, winners: "S.Connolly, A.T.Delaney", category: "women", notes: "Weyhey") }

    before(:each) do
      @user = login("editor")
      visit champion_path(champion)
      click_link edit
    end

    it "all" do
      fill_in year, with: data.year
      fill_in winners, with: data.winners
      select I18n.t("champion.category.#{data.category}"), from: category
      fill_in notes, with: data.notes
      click_button save

      expect(page).to have_css(success, text: updated)
      champion.reload

      expect(champion.year).to eq data.year
      expect(champion.winners).to eq data.winners
      expect(JournalEntry.champions.where(action: "update", by: @user.signature, journalable_id: champion.id).count).to eq 4
      %w[year winners category notes].each do |column|
        expect(JournalEntry.champions.where(action: "update", by: @user.signature, journalable_id: champion.id, column: column).count).to eq 1
      end
    end

    it "invalid year" do
      fill_in year, with: Global::MIN_YEAR - 1
      click_button save

      expect(page).to have_css(field_error, text: /must be ≥/)

      fill_in year, with: Date.today.year + 1
      click_button save

      expect(page).to have_css(field_error, text: /must be ≤/)

      expect(JournalEntry.champions.count).to eq 0

      fill_in year, with: Date.today.year
      click_button save

      expect(page).to have_css(success, text: updated)
      champion.reload

      expect(champion.year).to eq Date.today.year
      expect(JournalEntry.champions.where(action: "update", by: @user.signature, journalable_id: champion.id, column: "year").count).to eq 1
    end
  end

  context "destroy" do
    let!(:champion) { create(:champion) }

    before(:each) do
      @user = login("editor")
    end

    it "delete" do
      visit champions_path
      click_link champion.winners
      click_link delete

      expect(page).to have_css(success, text: deleted)
      expect(Champion.count).to eq 0
      expect(JournalEntry.champions.where(action: "destroy", by: @user.signature, journalable_id: champion.id).count).to eq 1
    end
  end
end
