require 'spec_helper'

feature JournalEntry do
  def create_club
    click_link "New Club"
    fill_in "Name", with: "Wandering Dragons"
    fill_in "City", with: "Bangor"
    select "Down", from: "County"
    fill_in "Email", with: "mark@markorr.net"
    click_button "Save"
    expect(page).to have_css(success)
    [Club.find_by(name: "Wandering Dragons"), JournalEntry.find_by(journalable_type: "Club", action: "create")]
  end

  def edit_translation
    translation = FactoryGirl.create(:translation) # translations aren't created via the web app
    visit admin_translation_path(translation)
    click_link "Edit"
    fill_in "translation_value", with: "bruscar"
    click_button "Save"
    [Translation.find_by(value: "bruscar"), JournalEntry.find_by(journalable_type: "Translation", action: "update", to: "bruscar")]
  end

  before(:each) do
    @admin = login "admin"
    @name = @admin.name[0,10]
    @ip = "127.0.0.1"
    @club, @club_creation = create_club
    @translation, @translation_change = edit_translation
  end

  given(:success)      { "div.alert-success" }
  given(:failure)      { "div.alert-danger" }
  given(:unauthorized) { I18n.t("errors.messages.unauthorized") }

  def xpath(id, *tds)
    xpath = "//table[@id='#{id}']/tbody/tr"
    if tds.any?
      xpath += "/td[starts-with(.,'#{tds.shift.to_s[0,10]}')]"
      tds.each do |text|
        xpath += "/following-sibling::td[starts-with(.,'#{text.to_s[0,10]}')]"
      end
    end
    xpath
  end

  scenario "admin view" do
    login "admin"

    visit club_path(@club)
    expect(page).to have_css("h4", text: "Changes")
    expect(page).to have_xpath(xpath("changes"), count: 1)
    expect(page).to have_xpath(xpath("changes", "create", @name), count: 1)

    visit admin_translation_path(@translation)
    expect(page).to have_css("h4", text: "Changes")
    expect(page).to have_xpath(xpath("changes"), count: 1)
    expect(page).to have_xpath(xpath("changes", "update", "value", "bruscar", @name), count: 1)

    visit admin_journal_entries_path
    expect(page).to have_xpath(xpath("results"), count: 2)
    expect(page).to have_xpath(xpath("results", "Translation", @translation.id, "update", "value", "bruscar", @name, @ip), count: 1)
    expect(page).to have_xpath(xpath("results", "Club", @club.id, "create", @name, @ip), count: 1)
  end

  scenario "editor view" do
    login "editor"

    visit club_path(@club)
    expect(page).to_not have_css("h4", text: "Changes")
    expect(page).to_not have_xpath(xpath("changes"))

    visit admin_translation_path(@translation)
    expect(page).to have_css(failure, text: unauthorized)

    visit admin_journal_entries_path
    expect(page).to have_css(failure, text: unauthorized)

    visit admin_journal_entry_path(@club_creation)
    expect(page).to have_css(failure, text: unauthorized)

    visit admin_journal_entry_path(@translation_change)
    expect(page).to have_css(failure, text: unauthorized)
  end

  scenario "translator view" do
    login "translator"

    visit club_path(@club)
    expect(page).to_not have_css("h4", text: "Changes")
    expect(page).to_not have_xpath(xpath("changes"))

    visit admin_translation_path(@translation)
    expect(page).to have_css("h4", text: "Changes")
    expect(page).to have_xpath(xpath("changes"), count: 1)

    visit admin_journal_entries_path
    expect(page).to have_css(failure, text: unauthorized)

    visit admin_journal_entry_path(@club_creation)
    expect(page).to have_css(failure, text: unauthorized)

    visit admin_journal_entry_path(@translation_change)
    expect(page).to_not have_css(failure)
  end

  scenario "treasurer view" do
    login "treasurer"

    visit club_path(@club)
    expect(page).to_not have_css("h4", text: "Changes")
    expect(page).to_not have_xpath(xpath("changes"))

    visit admin_translation_path(@translation)
    expect(page).to have_css(failure, text: unauthorized)

    visit admin_journal_entries_path
    expect(page).to have_css(failure, text: unauthorized)

    visit admin_journal_entry_path(@club_creation)
    expect(page).to have_css(failure, text: unauthorized)

    visit admin_journal_entry_path(@translation_change)
    expect(page).to have_css(failure, text: unauthorized)
  end
end
