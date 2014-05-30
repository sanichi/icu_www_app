require 'spec_helper'

describe "Authorization for pages" do
  let(:non_admin_roles) { User::ROLES.reject { |role| role == "admin" }.append("guest") }
  let(:paths)           { [admin_system_info_path, admin_test_email_path] }
  let(:success)         { "div.alert-success" }
  let(:failure)         { "div.alert-danger" }
  let(:unauthorized)    { I18n.t("errors.alerts.unauthorized") }

  it "admin role" do
    login "admin"
    paths.each do |path|
      visit path
      expect(page).to_not have_css(failure)
    end
  end

  it "other roles and guests" do
    non_admin_roles.each do |role|
      login role
      paths.each do |path|
        visit path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end
end
