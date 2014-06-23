require 'rails_helper'

describe Tournament do;
  include_context "features"

  let(:format)   { I18n.t("tournament.format.format") }

  let(:dup_error) { "once per year" }
  let(:header)    { "h1" }

  context "authorization" do
    let(:level1)     { %w[admin editor] }
    let(:level2)     { User::ROLES.reject { |role| level1.include?(role) }.append("guest") }
    let(:tournament) { create(:tournament) }

    it "level1 can manage tournaments" do
      level1.each do |role|
        login role
        visit new_admin_tournament_path
        expect(page).to_not have_css(failure)
        visit edit_admin_tournament_path(tournament)
        expect(page).to_not have_css(failure)
        visit tournament_path(tournament)
        expect(page).to have_css(header, text: tournament.name)
        expect(page).to have_link(edit)
      end
    end

    it "level2 can only view" do
      level2.each do |role|
        login role
        visit new_admin_tournament_path
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_tournament_path(tournament)
        expect(page).to have_css(failure, text: unauthorized)
        visit tournament_path(tournament)
        expect(page).to have_css(header, text: tournament.name)
        expect(page).to_not have_link(edit)
      end
    end
  end

  context "create" do
    let(:my_category) { "championship" }
    let(:my_city)     { "Armagh" }
    let(:my_details)  { "Champion: M.J.L.Orr\n\n9 round swiss, 20 players\n\nPlace Name       Score\n\n1     M.J.L.Orr  7\n\n2     B.Kelly    6" }
    let(:my_name)     { "Irish Championships" }
    let(:my_format)   { "swiss" }
    let(:my_year)     { 1994 }

    before(:each) do
      @user = login("editor")
      visit new_admin_tournament_path
      fill_in name, with: my_name
      fill_in year, with: my_year
      select I18n.t("tournament.category.#{my_category}"), from: category
      select I18n.t("tournament.format.#{my_format}"), from: format
      fill_in details, with: my_details
    end

    it "minimum data" do
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Tournament.count).to eq 1
      tournament = Tournament.first

      expect(tournament.active).to be false
      expect(tournament.category).to eq my_category
      expect(tournament.city).to be_nil
      expect(tournament.format).to eq my_format
      expect(tournament.name).to eq my_name
      expect(tournament.year).to eq my_year

      expect(JournalEntry.tournaments.where(action: "create", by: @user.signature, journalable_id: tournament.id).count).to eq 1
    end

    it "maximum data" do
      fill_in city, with: my_city
      check active
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Tournament.count).to eq 1
      tournament = Tournament.first

      expect(tournament.active).to be true
      expect(tournament.city).to eq my_city

      expect(JournalEntry.tournaments.where(action: "create", by: @user.signature, journalable_id: tournament.id).count).to eq 1
    end

    it "duplicate" do
      create(:tournament, name: my_name, year: my_year)
      click_button save

      expect(page).to_not have_css(success)
      expect(page).to have_css(field_error, text: dup_error)
      expect(Tournament.count).to eq 1

      fill_in year, with: my_year + 1
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Tournament.count).to eq 2
      expect(Tournament.first.year).to eq my_year
      expect(Tournament.last.year).to eq my_year + 1
    end
  end

  context "edit" do
    let(:tournament) { create(:tournament) }
    let(:my_year)    { tournament.year + 1 }

    before(:each) do
      @user = login("editor")
      visit tournament_path(tournament)
      click_link edit
    end

    it "year" do
      fill_in year, with: my_year
      click_button save

      expect(page).to have_css(success, text: updated)
      tournament.reload

      expect(tournament.year).to eq my_year
      expect(JournalEntry.tournaments.where(action: "update", by: @user.signature, journalable_id: tournament.id, column: "year").count).to eq 1
    end
  end

  context "destroy" do
    let!(:tournament) { create(:tournament) }

    before(:each) do
      @user = login("editor")
    end

    it "delete" do
      visit tournaments_path
      click_link tournament.name
      click_link delete

      expect(page).to have_css(success, text: deleted)
      expect(Tournament.count).to eq 0
      expect(JournalEntry.tournaments.where(action: "destroy", by: @user.signature, journalable_id: tournament.id).count).to eq 1
    end
  end
end
