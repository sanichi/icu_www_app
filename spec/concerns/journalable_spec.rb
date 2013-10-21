require 'spec_helper'

describe Journalable do
  def invalid(klass)
    valid = klass.column_names
    klass.journalable_columns.reject { |column| valid.include?(column) }.join(" ")
  end

  context Club do
    it "should be setup correctly" do
      expect(invalid(Club)).to be_blank
      expect(Club.journalable_path).to eq "/clubs/%d"
    end
  end

  context Player do
    it "should be setup correctly" do
      expect(invalid(Player)).to be_blank
      expect(Player.journalable_path).to eq "/admin/players/%d"
    end
  end

  context Translation do
    it "should be setup correctly" do
      expect(invalid(Translation)).to be_blank
      expect(Translation.journalable_path).to eq "/admin/translations/%d"
    end
  end

  context User do
    it "should be setup correctly" do
      expect(invalid(User)).to be_blank
      expect(User.journalable_path).to eq "/admin/users/%d"
    end
  end
end
