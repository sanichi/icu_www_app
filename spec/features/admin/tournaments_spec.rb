require 'spec_helper'

describe Tournament do
  let(:active)        { I18n.t("active") }
  let(:category_menu) { I18n.t("tournament.category.category") }
  let(:city_input)    { I18n.t("city") }
  let(:delete)        { I18n.t("delete") }
  let(:edit)          { I18n.t("edit") }
  let(:details_text)  { I18n.t("details") }
  let(:format_menu)   { I18n.t("tournament.format.format") }
  let(:name_input)    { I18n.t("name") }
  let(:save)          { I18n.t("save") }
  let(:unauthorized)  { I18n.t("unauthorized.default") }
  let(:year_input)    { I18n.t("year") }

  let(:dup_error)     { "once per year" }
  let(:failure)       { "div.alert-danger" }
  let(:field_error)   { "div.help-block" }
  let(:header)        { "h1" }
  let(:success)       { "div.alert-success" }
  let(:success_text)  { "successfully created" }

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
    let(:category) { "championship" }
    let(:city)     { "Armagh" }
    let(:details)  { "Champion: M.J.L.Orr\n\n9 round swiss, 20 players\n\nPlace Name       Score\n\n1     M.J.L.Orr  7\n\n2     B.Kelly    6" }
    let(:name)     { "Irish Championships" }
    let(:format)   { "swiss" }
    let(:year)     { 1994 }

    before(:each) do
      @user = login("editor")
      visit new_admin_tournament_path
      fill_in name_input, with: name
      fill_in year_input, with: year
      select I18n.t("tournament.category.#{category}"), from: category_menu
      select I18n.t("tournament.format.#{format}"), from: format_menu
      fill_in details_text, with: details
    end

    it "minimum data" do
      click_button save

      expect(page).to have_css(success, text: success_text)
      expect(Tournament.count).to eq 1
      tournament = Tournament.first

      expect(tournament.active).to be_false
      expect(tournament.category).to eq category
      expect(tournament.city).to be_nil
      expect(tournament.format).to eq format
      expect(tournament.name).to eq name
      expect(tournament.year).to eq year

      expect(JournalEntry.tournaments.where(action: "create", by: @user.signature, journalable_id: tournament.id).count).to eq 1
    end

    it "maximum data" do
      fill_in city_input, with: city
      check active
      click_button save

      expect(page).to have_css(success, text: success_text)
      expect(Tournament.count).to eq 1
      tournament = Tournament.first

      expect(tournament.active).to be_true
      expect(tournament.city).to eq city

      expect(JournalEntry.tournaments.where(action: "create", by: @user.signature, journalable_id: tournament.id).count).to eq 1
    end

    it "duplicate" do
      create(:tournament, name: name, year: year)
      click_button save

      expect(page).to_not have_css(success)
      expect(page).to have_css(field_error, text: dup_error)
      expect(Tournament.count).to eq 1

      fill_in year_input, with: year + 1
      click_button save

      expect(page).to have_css(success, text: success_text)
      expect(Tournament.count).to eq 2
      expect(Tournament.first.year).to eq year
      expect(Tournament.last.year).to eq year + 1
    end
  end

  context "edit" do
    let(:tournament) { create(:tournament) }
    let(:year)       { tournament.year + 1 }

    before(:each) do
      @user = login("editor")
      visit tournament_path(tournament)
      click_link edit
    end

    it "year" do
      fill_in year_input, with: year
      click_button save

      tournament.reload

      expect(tournament.year).to eq year
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

      expect(Tournament.count).to eq 0
      expect(JournalEntry.tournaments.where(action: "destroy", by: @user.signature, journalable_id: tournament.id).count).to eq 1
    end
  end
end
