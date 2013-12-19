require 'spec_helper'
require 'cancan/matchers'

describe Ability do
  context "class abilities" do
    actions = [:index, :show, :new, :edit, :destroy]
    no_show = actions.reject { |a| a == :show }
    class_abilities = {
      "admin" => [
        [:all, :manage]
      ],
      "editor" => [
        [Club, :manage],
        [Player, :show, no_show],
        [Translation, nil, actions],
        [User, nil, actions],
      ],
      "membership" => [
        [Club, nil, actions],
        [Player, :manage],
        [Translation, nil, actions],
        [User, nil, actions],
      ],
      "translator" => [
        [Player, :show, no_show],
        [Translation, :manage],
        [User, nil, actions],
      ],
      "treasurer" => [
        [Player, :show, no_show],
        [Translation, nil, actions],
        [User, nil, actions],
      ],
      "user" => [
        [Player, :show, no_show],
        [Translation, nil, actions],
        [User, nil, actions],
      ],
      "guest" => [
        [Player, nil, actions],
        [Translation, nil, actions],
        [User, nil, actions],
      ],
    }

    class_abilities.each do |role, allowances|
      user =
      case role
      when "guest"
        User::Guest.new
      when "user"
        FactoryGirl.create(:user)
      else
        FactoryGirl.create(:user, roles: role)
      end
      ability = Ability.new(user)

      allowances.each do |allowance|
        target, can, cant = *allowance

        can = Array(can)
        can.each do |action|
          it "#{role} can #{action} #{target}" do
            ability.should be_able_to action, target
          end
        end

        cant = Array(cant)
        cant.each do |action|
          it "#{role} cannot #{action} #{target}" do
            ability.should_not be_able_to action, target
          end
        end
      end
    end
  end
  
  context "instance abilities" do
    let(:player) { create(:player) }
    let(:ability) { Ability.new(user) }
    
    context "user" do
      let(:user) { create(:user) }
    
      it "can show only own player" do
        ability.should be_able_to :show, user.player
        ability.should_not be_able_to :show, player
      end
    end
  end

  context "entry fees" do
    let(:user)      { create(:user) }
    let(:other)     { create(:user) }
    let(:users_fee) { create(:entry_fee, event_name: "Kilkenny", player: user.player) }
    let(:other_fee) { create(:entry_fee, event_name: "Bunratty", player: other.player) }
    let(:nones_fee) { create(:entry_fee, event_name: "Galway") }
    let(:ability)   { Ability.new(user) }
    
    it "user can view their own fees" do
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
