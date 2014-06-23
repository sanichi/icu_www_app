require 'rails_helper'

describe "pages" do
  let(:home) { { :controller => "pages", :action => "home" } }

  it "root" do
    expect(:get => "/").to route_to home
    expect(:get => root_path).to route_to home
  end

  it "home" do
    expect(:get => "/home").to route_to home
    expect(:get => home_path).to route_to home
  end
end