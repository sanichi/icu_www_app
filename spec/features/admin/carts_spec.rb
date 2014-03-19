require 'spec_helper'

feature "Authorization for carts" do
  given(:ok_roles)        { %w[admin treasurer] }
  given(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) } }
  given(:cart)            { create(:cart) }
  given(:paths)           { [admin_carts_path, admin_cart_path(cart), edit_admin_cart_path(cart)] }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:unauthorized)    { I18n.t("errors.messages.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }

  scenario "some roles can view carts" do
    ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      paths.each do |path|
        visit path
        expect(page).to_not have_css(failure)
      end
    end
  end

  scenario "other roles and guests cannot" do
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
