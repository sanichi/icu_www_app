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
end
