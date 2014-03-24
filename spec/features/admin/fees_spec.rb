require 'spec_helper'

feature "Authorization for fees" do
  given(:ok_roles)        { %w[admin treasurer] }
  given(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) } }
  given(:fee)             { create(:subscription_fee) }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:button)          { I18n.t("edit") }
  given(:unauthorized)    { I18n.t("errors.alerts.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }
  given(:paths)           { [admin_fees_path, admin_fee_path(fee), edit_admin_fee_path(fee), new_admin_fee_path, clone_admin_fee_path(fee), rollover_admin_fee_path(fee)] }

  scenario "some roles can manage subscription fees" do
    ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      paths.each do |path|
        visit path
        expect(page).to_not have_css(failure)
      end
    end
  end

  scenario "other roles and guests have no access" do
    not_ok_roles.push("guest").each do |role|
      if role == "guest"
        logout
      else
        login role
        expect(page).to have_css(success, text: signed_in_as)
      end
      paths.each do |path|
        visit path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end
end
