require 'spec_helper'

describe "Authorization for fees" do
  let(:ok_roles)        { %w[admin treasurer] }
  let(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) }.append("guest") }
  let(:fee)             { create(:subscription_fee) }
  let(:success)         { "div.alert-success" }
  let(:failure)         { "div.alert-danger" }
  let(:button)          { I18n.t("edit") }
  let(:unauthorized)    { I18n.t("errors.alerts.unauthorized") }
  let(:signed_in_as)    { I18n.t("session.signed_in_as") }
  let(:paths)           { [admin_fees_path, admin_fee_path(fee), edit_admin_fee_path(fee), new_admin_fee_path, clone_admin_fee_path(fee), rollover_admin_fee_path(fee)] }

  it "some roles can manage subscription fees" do
    ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      paths.each do |path|
        visit path
        expect(page).to_not have_css(failure)
      end
    end
  end

  it "other roles and guests have no access" do
    not_ok_roles.each do |role|
      login role
      paths.each do |path|
        visit path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end
end
