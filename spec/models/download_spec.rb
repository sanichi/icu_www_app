require 'rails_helper'

describe Download do
  context "years in description" do
    let(:download) { build(:download, year: 2014) }

    it "no numbers" do
      download.description = "No numbers"
      expect(download).to be_valid
    end

    it "numbers but not years" do
      download.description = "The magic numbers 35, 371, 5141 and 99481"
      expect(download).to be_valid
    end

    it "rating bands not years" do
      download.description = "Bunratty under 1800 and under 2000"
      expect(download).to be_valid
    end

    it "issue numbers not years" do
      download.description = "Chess Today #1913"
      expect(download).to be_valid
    end

    it "correct year" do
      download.description = "EGM May 2014"
      expect(download).to be_valid
    end

    it "incorrect year" do
      download.description = "Irish Championships 1976"
      expect(download).to_not be_valid
      download.description = "Irish Championships 2015"
      expect(download).to_not be_valid
      download.description = "Chess Today #2014 2013"
      expect(download).to_not be_valid
    end

    it "correct seasons" do
      download.description = "AGM 2013/14"
      expect(download).to be_valid
      download.description = "AGM 2014-2015"
      expect(download).to be_valid
    end

    it "incorrect seasons" do
      download.description = "Cork Open 2012-13"
      expect(download).to_not be_valid
      download.description = "Cork Open 2015/2016"
      expect(download).to_not be_valid
    end
  end

  context "#accessible_to?" do
    let(:admin)  { create(:user, roles: "admin") }
    let(:editor) { create(:user, roles: "editor") }
    let(:guest)  { User::Guest.new }
    let(:member) { create(:user) }

    it "everyone" do
      download = create(:download, access: "all")
      expect(download.accessible_to?(admin)).to be true
      expect(download.accessible_to?(editor)).to be true
      expect(download.accessible_to?(member)).to be true
      expect(download.accessible_to?(guest)).to be true
    end

    it "members only" do
      download = create(:download, access: "members")
      expect(download.accessible_to?(admin)).to be true
      expect(download.accessible_to?(editor)).to be true
      expect(download.accessible_to?(member)).to be true
      expect(download.accessible_to?(guest)).to be false
    end

    it "editors only" do
      download = create(:download, access: "editors")
      expect(download.accessible_to?(admin)).to be true
      expect(download.accessible_to?(editor)).to be true
      expect(download.accessible_to?(member)).to be false
      expect(download.accessible_to?(guest)).to be false
    end

    it "admins only" do
      download = create(:download, access: "admins")
      expect(download.accessible_to?(admin)).to be true
      expect(download.accessible_to?(editor)).to be false
      expect(download.accessible_to?(member)).to be false
      expect(download.accessible_to?(guest)).to be false
    end
  end

  context "validation" do
    it "invalid" do
      download = build(:download, access: "INVALID")
      expect(download).to_not be_valid
    end
  end
end
