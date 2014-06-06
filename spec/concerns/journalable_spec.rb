require 'spec_helper'

describe Journalable do
  def invalid(klass)
    valid = klass.column_names
    klass.journalable_columns.reject { |column| valid.include?(column) }.join(" ")
  end

  [
    [Article, "/article/%d"],
    [Club, "/clubs/%d"],
    [Event, "/events/%d"],
    [Fee, "/admin/fees/%d"],
    [Game, "/games/%d"],
    [Image, "/images/%d"],
    [Pgn, "/admin/pgns/%d"],
    [Player, "/admin/players/%d"],
    [Tournament, "/tournaments/%d"],
    [Translation, "/admin/translations/%d"],
    [Upload, "/admin/uploads/%d"],
    [User, "/admin/users/%d"],
    [UserInput, "/admin/user_inputs/%d"],
  ].each do |klass, path|
    context klass do
      it "setup correctly" do
        expect(invalid(klass)).to eq ""
        expect(klass.journalable_path).to eq path
        expect(JournalEntry).to respond_to(klass.to_s.tableize.to_sym)
      end
    end
  end
end
