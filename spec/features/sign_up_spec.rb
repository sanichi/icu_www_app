require 'rails_helper'

describe "Sign up" do
  include_context "features"

  let(:account)     { I18n.t("user.account") }
  let(:complete)    { I18n.t("user.complete_registration") }
  let(:completed)   { I18n.t("user.completed_registration") }
  let(:created)     { I18n.t("user.created") }
  let(:digits)      { I18n.t("errors.attributes.password.digits") }
  let(:expired)     { I18n.t("errors.attributes.ticket.expired") }
  let(:icu_id)      { I18n.t("player.id") }
  let(:incomplete)  { I18n.t("user.incomplete_registration") }
  let(:invalid)     { I18n.t("errors.messages.invalid") }
  let(:length)      { I18n.t("errors.attributes.password.length", minimum: User::MINIMUM_PASSWORD_LENGTH) }
  let(:mismatch)    { I18n.t("errors.attributes.ticket.mismatch") }
  let(:new_account) { I18n.t("user.new") }
  let(:password)    { I18n.t("user.password") }
  let(:sign_in)     { I18n.t("session.sign_in") }
  let(:taken)       { I18n.t("errors.messages.taken") }
  let(:ticket)      { I18n.t("user.ticket") }
  let(:unverified)  { I18n.t("session.unverified_email") }

  let(:player) { create(:player) }
  let(:data)   { build(:user, player: player) }

  let(:season_ticket) { SeasonTicket.new(player.id, data.expires_on) }

  before(:each) do
    visit sign_up_path
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  context "success" do
    let(:valid_password) { "abcdef7" }

    before(:each) do
      fill_in icu_id, with: player.id
      fill_in ticket, with: season_ticket
      fill_in email, with: data.email
      fill_in password, with: valid_password
      click_button save
    end

    it "create" do
      expect(page.title).to eq account
      expect(page).to have_css(success, text: created)
      expect(page).to have_text(complete)

      expect(User.count).to eq 1
      user = User.first

      expect(JournalEntry.users.where(action: "create", by: user.signature, journalable_id: user.id).count).to eq 1

      expect(user.player).to eq player
      expect(user.email).to eq data.email
      expect(user.valid_password?(valid_password)).to eq true
      expect(user.expires_on).to eq data.expires_on
      expect(user.verified_at).to be_nil
      expect(user.status).to eq User::OK
      expect(user.roles).to be_nil
      expect(user.theme).to be_nil
      expect(user.locale).to eq "en"

      expect(ActionMailer::Base.deliveries.size).to eq 1
      email = ActionMailer::Base.deliveries.last
      expect(email.from.size).to eq 1
      expect(email.from.first).to eq IcuMailer::FROM
      expect(email.to.size).to eq 1
      expect(email.to.first).to eq user.email
      expect(email.subject).to eq IcuMailer::VERIFICATION

      text = email.body.decoded
      expect(text).to include(player.name(id: true))
      expect(text).to include(user.email)
      expect(text).to include("http://www.icu.ie/users/%d/verify?vp=%s" % [user.id, user.verification_param])
    end

    it "verify and login" do
      expect(User.count).to eq 1
      user = User.first
      expect(user.verified_at).to be_nil

      visit verify_user_path(user, vp: user.verification_param)
      expect(page).to have_css(success, text: completed)

      expect(JournalEntry.users.where(action: "update", by: user.signature, journalable_id: user.id, column: "verified_at").count).to eq 1

      user.reload
      expect(user.verified_at).to_not be_nil

      expect(page.title).to eq sign_in
      fill_in email, with: user.email
      fill_in password, with: valid_password
      click_button sign_in
      expect(page).to have_css(success, text: signed_in_as)
    end

    it "verify twice" do
      expect(User.count).to eq 1
      user = User.first
      expect(JournalEntry.users.count).to eq 1

      visit verify_user_path(user, vp: user.verification_param)
      expect(page).to have_css(success, text: completed)
      expect(page.title).to eq sign_in

      expect(JournalEntry.users.count).to eq 2

      visit verify_user_path(user, vp: user.verification_param)
      expect(page).to_not have_css(success)
      expect(page).to_not have_css(failure)
      expect(page.title).to eq sign_in

      expect(JournalEntry.users.count).to eq 2
    end

    it "incorrect verification" do
      expect(JournalEntry.users.count).to eq 1
      expect(User.count).to eq 1
      user = User.first
      expect(user.verified_at).to be_nil

      visit verify_user_path(user, vp: "")
      expect(page).to_not have_css(success)
      expect(page).to_not have_css(failure)

      user.reload
      expect(user.verified_at).to be_nil

      expect(page.title).to eq sign_in
      fill_in email, with: user.email
      fill_in password, with: valid_password
      click_button sign_in
      expect(page).to have_css(failure, text: unverified)

      expect(JournalEntry.users.count).to eq 1
    end
  end

  context "failure" do
    let(:season_ticket)  { SeasonTicket.new(player.id, data.expires_on) }
    let(:valid_password) { "abcdef7" }

    def field_err(atr)
      %Q{//input[@id="#{atr}"]/parent::div[contains(@class,"field_with_errors")]/parent::div/following-sibling::div[contains(@class,"help-block")]}
    end

    def nothing_happened(users=0)
      expect(User.count).to eq users
      expect(JournalEntry.count).to eq 0
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "nothing filled in" do
      click_button save
      expect(page.title).to eq new_account
      expect(page).to have_xpath(field_err(:user_player_id), text: invalid)

      nothing_happened
    end

    it "invalid ICU ID" do
      fill_in icu_id, with: player.id + 100
      click_button save
      expect(page.title).to eq new_account
      expect(page).to have_xpath(field_err(:user_player_id), text: invalid)

      nothing_happened
    end

    it "missing season ticket" do
      fill_in icu_id, with: player.id
      click_button save
      expect(page.title).to eq new_account
      expect(page).to have_xpath(field_err(:user_ticket), text: invalid)

      nothing_happened
    end

    it "invalid season ticket" do
      fill_in icu_id, with: player.id
      fill_in ticket, with: "rubbish"
      click_button save
      expect(page.title).to eq new_account
      expect(page).to have_xpath(field_err(:user_ticket), text: invalid)

      nothing_happened
    end

    it "mismatched season ticket" do
      fill_in icu_id, with: player.id
      fill_in ticket, with: SeasonTicket.new(player.id + 100, data.expires_on)
      click_button save
      expect(page.title).to eq new_account
      expect(page).to have_xpath(field_err(:user_ticket), text: mismatch)

      nothing_happened
    end

    it "expired season ticket" do
      fill_in icu_id, with: player.id
      fill_in ticket, with: SeasonTicket.new(player.id, Date.yesterday)
      click_button save
      expect(page.title).to eq new_account
      expect(page).to have_xpath(field_err(:user_ticket), text: expired)

      nothing_happened
    end

    it "missing email" do
      fill_in icu_id, with: player.id
      fill_in ticket, with: season_ticket
      fill_in password, with: valid_password
      click_button save
      expect(page.title).to eq new_account
      expect(page).to have_xpath(field_err(:user_email), text: invalid)

      nothing_happened
    end

    it "rubbish email" do
      fill_in icu_id, with: player.id
      fill_in ticket, with: season_ticket
      fill_in email, with: "rubbish"
      fill_in password, with: valid_password
      click_button save
      expect(page.title).to eq new_account
      expect(page).to have_xpath(field_err(:user_email), text: invalid)

      nothing_happened
    end

    it "taken email" do
      user = create(:user)
      fill_in icu_id, with: player.id
      fill_in ticket, with: season_ticket
      fill_in email, with: user.email
      fill_in password, with: valid_password
      click_button save
      expect(page.title).to eq new_account
      expect(page).to have_xpath(field_err(:user_email), text: taken)

      nothing_happened(1)
    end

    it "unverified email" do
      create(:user, player: player, email: data.email, verified_at: nil)
      fill_in icu_id, with: player.id
      fill_in ticket, with: season_ticket
      fill_in email, with: data.email
      fill_in password, with: valid_password
      click_button save
      expect(page.title).to eq new_account
      expect(page).to have_xpath(field_err(:user_email), text: incomplete)

      nothing_happened(1)
    end

    it "missing password" do
      fill_in icu_id, with: player.id
      fill_in ticket, with: season_ticket
      fill_in email, with: data.email
      click_button save
      expect(page.title).to eq new_account
      expect(page).to have_xpath(field_err(:user_password), text: invalid)

      nothing_happened
    end

    it "password too short" do
      fill_in icu_id, with: player.id
      fill_in ticket, with: season_ticket
      fill_in email, with: data.email
      fill_in password, with: "xyz1"
      click_button save
      expect(page.title).to eq new_account
      expect(page).to have_xpath(field_err(:user_password), text: length)

      nothing_happened
    end

    it "password needs digits" do
      fill_in icu_id, with: player.id
      fill_in ticket, with: season_ticket
      fill_in email, with: data.email
      fill_in password, with: "abcdefg"
      click_button save
      expect(page.title).to eq new_account
      expect(page).to have_xpath(field_err(:user_password), text: digits)

      nothing_happened
    end
  end
end
