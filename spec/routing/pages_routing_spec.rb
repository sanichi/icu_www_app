require 'rails_helper'

describe "routes" do
  context "pages" do
    let(:home) { { :controller => "pages", :action => "home" } }

    it "root" do
      expect(get: "/").to route_to home
      expect(get: root_path).to route_to home
    end

    it "home" do
      expect(get: "/home").to route_to home
      expect(get: home_path).to route_to home
    end
  end

  context "sign up" do
    let(:unroutable) { { :controller => "pages", :action => "not_found" } }

    it "can't get to the confirm page" do
      %w[/users/confirm/1 /users/confirm].each do |url|
        expect(get: url).to route_to unroutable.merge(url: url[1..-1])
      end
    end
  end
end
