require 'spec_helper'

describe "Authorization for payment errors" do
  let(:ok_roles)        { %w[admin treasurer] }
  let(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) } }
  let(:paths)           { [admin_payment_errors_path] }
  let(:success)         { "div.alert-success" }
  let(:failure)         { "div.alert-danger" }
  let(:unauthorized)    { I18n.t("errors.alerts.unauthorized") }
  let(:signed_in_as)    { I18n.t("session.signed_in_as") }

  it "some roles can list payment errors" do
    ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      paths.each do |path|
        visit path
        expect(page).to_not have_css(failure)
      end
    end
  end

  it "other roles and guests cannot" do
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
