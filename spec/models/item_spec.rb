require 'spec_helper'

describe Item do
  context "duplicate_of?" do
    let(:sub) { create(:subscription_item) }
    let(:ent) { create(:entri_item) }

    it "items with different subclasses" do
      expect(sub.duplicate_of?(ent)).to be_false
      expect(ent.duplicate_of?(sub)).to be_false
    end
  end
end
