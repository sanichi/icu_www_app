# encoding: utf-8
require 'spec_helper'

feature "Authorization for clubs" do
  given(:ok_roles)        { %w[admin editor] }
  given(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) } }
  given(:club)            { FactoryGirl.create(:club) }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:header)          { "//h1[.='#{club.name}']" }
  given(:button)          { I18n.t("edit") }
  given(:unauthorized)    { I18n.t("errors.messages.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }

  scenario "the admin and editor roles can edit clubs" do
    ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      visit edit_admin_club_path(club)
      expect(page).not_to have_css(failure)
      visit club_path(club)
      expect(page).to have_xpath(header)
      expect(page).to have_link(button)
    end
  end

  scenario "other roles cannot edit clubs" do
    not_ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      visit edit_admin_club_path(club)
      expect(page).to have_css(failure, text: unauthorized)
      visit club_path(club)
      expect(page).to have_xpath(header)
      expect(page).to_not have_link(button)
    end
  end

  scenario "guests cannot edit users" do
    logout
    visit edit_admin_club_path(club)
    expect(page).to have_css(failure, text: unauthorized)
    visit club_path(club)
    expect(page).to have_xpath(header)
    expect(page).to_not have_link(button)
  end
end
