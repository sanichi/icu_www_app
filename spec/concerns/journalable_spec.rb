require 'spec_helper'

describe Journalable do
  def invalid(klass)
    valid = klass.column_names
    klass.journalable_columns.reject { |column| valid.include?(column) }.join(" ")
  end

  [
    [Club, "/clubs/%d"],
    [Player, "/admin/players/%d"],
    [Translation, "/admin/translations/%d"],
    [User, "/admin/users/%d"],
    [SubscriptionFee, "/admin/subscription_fees/%d"],
    [EntryFee, "/admin/entry_fees/%d"],
  ].each do |klass, path|
    context klass do
      it "should be setup correctly" do
        expect(invalid(klass)).to eq ""
        expect(klass.journalable_path).to eq path
      end
    end
  end
end
