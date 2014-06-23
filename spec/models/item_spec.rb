require 'rails_helper'

describe Item do
  context "duplicate_of?" do
    let(:sub) { create(:subscription_item) }
    let(:ent) { create(:entry_item) }

    it "items with different subclasses" do
      expect(sub.duplicate_of?(ent)).to be false
      expect(ent.duplicate_of?(sub)).to be false
    end
  end
end
