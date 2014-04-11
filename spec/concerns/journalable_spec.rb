require 'spec_helper'

describe Journalable do
  def invalid(klass)
    valid = klass.column_names
    klass.journalable_columns.reject { |column| valid.include?(column) }.join(" ")
  end

  [
    [Club, "/clubs/%d"],
    [Fee, "/admin/fees/%d"],
    [Player, "/admin/players/%d"],
    [Translation, "/admin/translations/%d"],
    [User, "/admin/users/%d"],
    [UserInput, "/admin/user_inputs/%d"],
  ].each do |klass, path|
    context klass do
      it "setup correctly" do
        expect(invalid(klass)).to eq ""
        expect(klass.journalable_path).to eq path
      end
    end
  end
end
