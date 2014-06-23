require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  context Player do
    let(:player) { create(:player) }
    let(:ability) { Ability.new(user) }

    context "user" do
      let(:user) { create(:user) }

      it "can only view own player" do
        expect(ability.can?(:show, user.player)).to be true
        expect(ability.can?(:show, player)).to be false
      end
    end
  end
end
