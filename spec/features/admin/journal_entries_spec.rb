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
    translation = create(:translation) # translations aren't created via the web app
    visit admin_translation_path(translation)
    click_link "Edit"
    fill_in "translation_value", with: "bruscar"
    click_button "Save"
    [Translation.find_by(value: "bruscar"), JournalEntry.find_by(journalable_type: "Translation", action: "update", to: "bruscar")]
  end

  def edit_user
    user = create(:user) # users aren't created via the web app
    visit admin_user_path(user)
    click_link "Edit"
    fill_in "Status", with: "banned"
    click_button "Save"
    [User.find_by(status: "banned"), JournalEntry.find_by(journalable_type: "User", action: "update", to: "banned")]
  end

  def xpath(id, *tds)
    xpath = %Q{//table[@id="#{id}"]/tbody/tr}
    if tds.any?
      xpath += %Q{/td[starts-with(.,"#{tds.shift.to_s[0,10]}")]}
      tds.each do |text|
        xpath += %Q{/following-sibling::td[starts-with(.,"#{text.to_s[0,10]}")]}
      end
    end
    xpath
  end

  before(:each) do
    @admin = login "admin"
    @name = @admin.signature[0,10]
    @ip = "127.0.0.1"
    @club, @club_creation = create_club
    @translation, @translation_change = edit_translation
    @user, @user_change = edit_user
  end

  given(:success)      { "div.alert-success" }
  given(:failure)      { "div.alert-danger" }
  given(:unauthorized) { I18n.t("errors.messages.unauthorized") }

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

    visit admin_user_path(@user)
    expect(page).to have_css("h4", text: "Changes")
    expect(page).to have_xpath(xpath("changes"), count: 1)
    expect(page).to have_xpath(xpath("changes", "update", "status", "banned", @name), count: 1)

    visit admin_journal_entries_path
    expect(page).to have_xpath(xpath("results"), count: 3)
    expect(page).to have_xpath(xpath("results", "Club", @club.id, "create", @name, @ip), count: 1)
    expect(page).to have_xpath(xpath("results", "Translation", @translation.id, "update", "value", "bruscar", @name, @ip), count: 1)
    expect(page).to have_xpath(xpath("results", "User", @user.id, "update", "status", "banned", @name, @ip), count: 1)
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

    visit admin_user_path(@user_change)
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

    visit admin_user_path(@user_change)
    expect(page).to have_css(failure, text: unauthorized)
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

    visit admin_user_path(@user_change)
    expect(page).to have_css(failure, text: unauthorized)
  end

  scenario "delete parent object" do
    expect(JournalEntry.where(journalable_type: "Translation").count).to eq 1

    @translation.active = false
    @translation.save
    login "admin"
    visit admin_translation_path(@translation)
    click_link "Delete"

    expect(JournalEntry.where(journalable_type: "Translation").count).to eq 2
  end
end
