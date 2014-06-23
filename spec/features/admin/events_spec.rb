require 'rails_helper'

describe Event do;
  include_context "features"

  let(:category)      { I18n.t("event.category.category") }
  let(:contact)       { I18n.t("event.contact") }
  let(:event_email)   { I18n.t("event.email") }
  let(:end_date)      { I18n.t("event.end") }
  let(:flyer)         { I18n.t("event.flyer") }
  let(:lat)           { I18n.t("event.lat") }
  let(:location)      { I18n.t("event.location") }
  let(:long)          { I18n.t("event.long") }
  let(:event_name)    { I18n.t("event.name") }
  let(:phone)         { I18n.t("event.phone") }
  let(:prize_fund)    { I18n.t("event.prize_fund") }
  let(:start_date)    { I18n.t("event.start") }
  let(:url)           { I18n.t("event.url") }

  let(:doc)           { "kilkenny_2005.doc" }
  let(:docx)          { "bray_2014.docx" }
  let(:pdf)           { "ennis_2014.pdf" }
  let(:rtf)           { "galway_2005.rtf" }

  let(:event_dir)     { Rails.root + "spec/files/events/" }
  let(:image_dir)     { Rails.root + "spec/files/images/" }

  context "authorization" do
    let(:level1) { ["admin", user] }
    let(:level2) { ["calendar", "editor"] }
    let(:level3) { User::ROLES.reject { |r| r.match(/\A(admin|editor|calendar)\z/) }.append("guest") }
    let(:user)   { create(:user, roles: "calendar") }

    let(:event)  { create(:event, user: user) }

    def cell(label)
      "//th[.='#{label}']/following-sibling::td"
    end

    it "level 1 can update as well as create" do
      level1.each do |role|
        login role
        visit new_admin_event_path
        expect(page).to_not have_css(failure)
        visit edit_admin_event_path(event)
        expect(page).to_not have_css(failure)
        visit events_path
        click_link event.name
        expect(page).to have_xpath(cell(event_name), text: event.name)
        expect(page).to have_link(edit)
      end
    end

    it "level 2 can only create" do
      level2.each do |role|
        login role
        visit new_admin_event_path
        expect(page).to_not have_css(failure)
        visit edit_admin_event_path(event)
        expect(page).to have_css(failure)
        visit events_path
        click_link event.name
        expect(page).to have_xpath(cell(event_name), text: event.name)
        expect(page).to_not have_link(edit)
      end
    end

    it "level 3 can only view" do
      level3.each do |role|
        login role
        visit new_admin_event_path
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_event_path(event)
        expect(page).to have_css(failure, text: unauthorized)
        visit events_path
        click_link event.name
        expect(page).to have_xpath(cell(event_name), text: event.name)
        expect(page).to_not have_link(edit)
      end
    end
  end

  context "create" do
    let(:contact_text)  { "Gerry Graham" }
    let(:email_text)    { "gerrygraham@eircom.net" }
    let(:lat_text)      { "52.696169" }
    let(:long_text)     { "-8.815144" }
    let(:location_text) { "Bunratty, Limerick" }
    let(:name_text)     { "Bunratty Congress" }
    let(:note_text)     { "The best Irish tournament." }
    let(:start)         { Date.today.years_since(1) }
    let(:phone_text)    { "0872273593" }
    let(:fund_text)     { "3250" }
    let(:url_text)      { "http://www.bunrattychess.com/home/index.php" }
    let(:finish)        { start.days_since(2) }

    before(:each) do
      @user = login("calendar")
      visit new_admin_event_path
      fill_in end_date, with: finish.to_s
      fill_in location, with: location_text
      fill_in event_name, with: name_text
      fill_in start_date, with: start.to_s
    end

    it "minimum data" do
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Event.count).to eq 1
      event = Event.first

      expect(event.active).to be false
      expect(event.category).to eq Event::CATEGORIES[0]
      expect(event.contact).to be_nil
      expect(event.email).to be_nil
      expect(event.end_date).to eq finish
      expect(event.flyer).to be_blank
      expect(event.lat).to be_nil
      expect(event.location).to eq location_text
      expect(event.long).to be_nil
      expect(event.name).to eq name_text
      expect(event.note).to be_nil
      expect(event.phone).to be_nil
      expect(event.prize_fund).to be_nil
      expect(event.source).to eq "www2"
      expect(event.start_date).to eq start
      expect(event.url).to be_nil
      expect(event.user).to eq @user
    end

    it "maximum data" do
      check active
      select I18n.t("event.category.#{Event::CATEGORIES[1]}"), from: category
      fill_in contact, with: contact_text
      fill_in event_email, with: email_text
      fill_in lat, with: lat_text
      fill_in long, with: long_text
      fill_in notes, with: note_text
      fill_in phone, with: phone_text
      fill_in prize_fund, with: fund_text
      fill_in url, with: url_text
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Event.count).to eq 1
      event = Event.first

      expect(event.active).to be true
      expect(event.category).to eq Event::CATEGORIES[1]
      expect(event.contact).to eq contact_text
      expect(event.email).to eq email_text
      expect(event.end_date).to eq finish
      expect(event.flyer).to be_blank
      expect(event.lat).to eq lat_text.to_f
      expect(event.location).to eq location_text
      expect(event.long).to eq long_text.to_f
      expect(event.name).to eq name_text
      expect(event.note).to eq note_text
      expect(event.phone).to eq phone_text
      expect(event.prize_fund).to eq fund_text.to_f
      expect(event.source).to eq "www2"
      expect(event.start_date).to eq start
      expect(event.url).to eq url_text
      expect(event.user).to eq @user
    end

    it "PDF" do
      attach_file flyer, event_dir + pdf
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Event.count).to eq 1
      event = Event.first

      expect(event.flyer_file_name).to eq pdf
      expect(event.flyer_file_size).to eq 41571
      expect(event.flyer_content_type).to eq "application/pdf"
    end

    it "DOCX" do
      attach_file flyer, event_dir + docx
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Event.count).to eq 1
      event = Event.first

      expect(event.flyer_file_name).to eq docx
      expect(event.flyer_file_size).to eq 14734
      expect(event.flyer_content_type).to eq "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    end

    it "DOC" do
      attach_file flyer, event_dir + doc
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Event.count).to eq 1
      event = Event.first

      expect(event.flyer_file_name).to eq doc
      expect(event.flyer_file_size).to eq 48128
      expect(event.flyer_content_type).to eq "application/msword"
    end

    it "RTF" do
      attach_file flyer, event_dir + rtf
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Event.count).to eq 1
      event = Event.first

      expect(event.flyer_file_name).to eq rtf
      expect(event.flyer_file_size).to eq 6846
      expect(event.flyer_content_type).to match /\A(application|text)\/rtf\z/
    end

    it "invalid file type" do
      attach_file flyer, image_dir + "april.jpeg"
      click_button save

      expect(page).to_not have_css(success)
      expect(page).to have_css(field_error, text: "invalid")
      expect(Event.count).to eq 0
    end

    it "file too big" do
      attach_file flyer, event_dir + "too_large.pdf"
      click_button save

      expect(page).to_not have_css(success)
      expect(page).to have_css(field_error, text: "between")
      expect(Event.count).to eq 0
    end

    it "file too small" do
      attach_file flyer, event_dir + "too_small.rtf"
      click_button save

      expect(page).to_not have_css(success)
      expect(page).to have_css(field_error, text: "between")
      expect(Event.count).to eq 0
    end
  end
end
