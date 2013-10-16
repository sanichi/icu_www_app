require 'spec_helper'

describe Journalable do
  context Club do
    it "should be setup correctly" do
      expect(Club.journalable_columns).to eq Set.new(%w[name web meet address district city county lat long contact email phone active])
      expect(Club.journalable_path).to eq "/clubs/%d"
    end
  end

  context Translation do
    it "should be setup correctly" do
      expect(Translation.journalable_columns).to eq Set.new(%w[value])
      expect(Translation.journalable_path).to eq "/admin/translations/%d"
    end
  end
end
