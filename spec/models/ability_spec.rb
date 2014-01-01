require 'spec_helper'
require 'cancan/matchers'

describe Ability do
  context Player do
    let(:player) { create(:player) }
    let(:ability) { Ability.new(user) }
    
    context "user" do
      let(:user) { create(:user) }
    
      it "can only view own player" do
        ability.should be_able_to :show, user.player
        ability.should_not be_able_to :show, player
      end
    end
  end

  context EntryFee do
    let(:user)      { create(:user) }
    let(:other)     { create(:user) }
    let(:users_fee) { create(:entry_fee, event_name: "Kilkenny", player: user.player) }
    let(:other_fee) { create(:entry_fee, event_name: "Bunratty", player: other.player) }
    let(:nones_fee) { create(:entry_fee, event_name: "Galway") }
    let(:ability)   { Ability.new(user) }
    
    context "user" do
      it "user only view their own fees" do
        [:show].each { |action| ability.should be_able_to action, users_fee }
        [:edit, :update].each { |action| ability.should_not be_able_to action, users_fee }
        [:index, :new, :create].each { |action| ability.should_not be_able_to action, EntryFee }
        [other_fee, nones_fee].each do |fee|
          [:show, :create, :edit, :update].each { |action| ability.should_not be_able_to action, fee }
          [:index, :new].each { |action| ability.should_not be_able_to action, EntryFee }
        end
      end
    end
  end
end
