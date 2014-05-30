require 'spec_helper'

describe "Authorization for carts" do
  let(:ok_roles)        { %w[admin treasurer] }
  let(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) }.append("guest") }
  let(:cart)            { create(:cart) }
  let(:paths)           { [admin_carts_path, admin_cart_path(cart), edit_admin_cart_path(cart)] }
  let(:success)         { "div.alert-success" }
  let(:failure)         { "div.alert-danger" }
  let(:unauthorized)    { I18n.t("errors.alerts.unauthorized") }

  it "some roles can view carts" do
    ok_roles.each do |role|
      login role
      paths.each do |path|
        visit path
        expect(page).to_not have_css(failure)
      end
    end
  end

  it "other roles and guests cannot" do
    not_ok_roles.each do |role|
      login role
      paths.each do |path|
        visit path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end
end
