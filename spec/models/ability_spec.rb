require 'spec_helper'
require 'cancan/matchers'

describe Ability do
  let(:ability) { Ability.new(user) }

  context "admin" do
    let(:user) { FactoryGirl.create(:user, roles: "admin") }

    it "all" do
      ability.should be_able_to :manage, :all
    end
  end

  context "editor" do
    let(:user) { FactoryGirl.create(:user, roles: "editor") }

    it "clubs" do
      ability.should be_able_to :manage, Club
    end

    it "journal entries" do
      ability.should_not be_able_to :read, JournalEntry
    end

    it "logins" do
      ability.should_not be_able_to :read, Login
    end

    it "translations" do
      ability.should_not be_able_to :read, Translation
    end

    it "users" do
      ability.should_not be_able_to :read, User
    end
  end

  context "translator" do
    let(:user) { FactoryGirl.create(:user, roles: "translator") }
    subject    { ability }

    it "clubs" do
      ability.should_not be_able_to :manage, Club
    end

    it "journal entries" do
      ability.should_not be_able_to :index, JournalEntry
      ability.should_not be_able_to :show, JournalEntry.new(journalable_type: "Club")
      ability.should be_able_to :show, JournalEntry.new(journalable_type: "Translation")
    end

    it "logins" do
      ability.should_not be_able_to :read, Login
    end

    it "translations" do
      ability.should be_able_to :manage, Translation
    end

    it "users" do
      ability.should_not be_able_to :read, User
    end
  end

  context "treasurer" do
    let(:user) { FactoryGirl.create(:user, roles: "treasurer") }

    it "clubs" do
      ability.should_not be_able_to :manage, Club
    end

    it "journal entries" do
      ability.should_not be_able_to :read, JournalEntry
    end

    it "logins" do
      ability.should_not be_able_to :read, Login
    end

    it "translations" do
      ability.should_not be_able_to :read, Translation
    end

    it "users" do
      ability.should_not be_able_to :read, User
    end
  end
end
