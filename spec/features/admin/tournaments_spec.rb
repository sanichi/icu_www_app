require 'spec_helper'

describe Tournament do
  let(:champs)       { "championship" }
  let(:dup_error)    { "once per year" }
  let(:failure)      { "div.alert-danger" }
  let(:field_error)  { "div.help-block" }
  let(:header)       { "h1" }
  let(:success)      { "div.alert-success" }
  let(:success_text) { "successfully created" }
  let(:swiss)        { "swiss" }

  let(:active)       { I18n.t("active") }
  let(:category_)    { I18n.t("tournament.category.category") }
  let(:city_)        { I18n.t("city") }
  let(:delete)       { I18n.t("delete") }
  let(:edit)         { I18n.t("edit") }
  let(:details_)     { I18n.t("details") }
  let(:format_)      { I18n.t("tournament.format.format") }
  let(:name_)        { I18n.t("name") }
  let(:save)         { I18n.t("save") }
  let(:unauthorized) { I18n.t("errors.alerts.unauthorized") }
  let(:year_)        { I18n.t("year") }

  context "authorization" do
    let(:not_ok_roles) { User::ROLES.reject { |role| ok_roles.include?(role) }.append("guest") }
    let(:ok_roles)     { %w[admin editor] }
    let(:tournament)   { create(:tournament) }

    it "some roles can manage tournaments as well as view" do
      ok_roles.each do |role|
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

    it "other roles and guests can only view" do
      not_ok_roles.each do |role|
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
    let(:champs_) { I18n.t("tournament.category.#{champs}") }
    let(:city)    { "Armagh" }
    let(:details) { "Champion: M.J.L.Orr\n\n9 round swiss, 20 players\n\nPlace Name       Score\n\n1     M.J.L.Orr  7\n\n2     B.Kelly    6" }
    let(:name)    { "Irish Championships" }
    let(:swiss_)  { I18n.t("tournament.format.#{swiss}") }
    let(:year)    { 1994 }

    before(:each) do
      @user = login("editor")
      visit new_admin_tournament_path
      fill_in name_, with: name
      fill_in year_, with: year
      select champs_, from: category_
      select swiss_, from: format_
      fill_in details_, with: details
    end

    it "minimum data" do
      click_button save

      expect(page).to have_css(success, text: success_text)
      expect(Tournament.count).to eq 1
      tournament = Tournament.first

      expect(tournament.active).to be_false
      expect(tournament.category).to eq champs
      expect(tournament.city).to be_nil
      expect(tournament.format).to eq swiss
      expect(tournament.name).to eq name
      expect(tournament.year).to eq year

      expect(JournalEntry.tournaments.where(action: "create", by: @user.signature, journalable_id: tournament.id).count).to eq 1
    end

    it "maximum data" do
      fill_in city_, with: city
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

      fill_in year_, with: year + 1
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
      fill_in year_, with: year
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
