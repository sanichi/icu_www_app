require 'spec_helper'

describe Upload do
  context "years in description" do
    let(:upload) { build(:upload, year: 2014) }

    it "no numbers" do
      upload.description = "No numbers"
      expect(upload).to be_valid
    end

    it "numbers but not years" do
      upload.description = "The magic numbers 35, 371, 5141 and 99481"
      expect(upload).to be_valid
    end

    it "rating bands not years" do
      upload.description = "Bunratty under 1800 and under 2000"
      expect(upload).to be_valid
    end

    it "issue numbers not years" do
      upload.description = "Chess Today #1913"
      expect(upload).to be_valid
    end

    it "correct year" do
      upload.description = "EGM May 2014"
      expect(upload).to be_valid
    end

    it "incorrect year" do
      upload.description = "Irish Championships 1976"
      expect(upload).to_not be_valid
      upload.description = "Irish Championships 2015"
      expect(upload).to_not be_valid
      upload.description = "Chess Today #2014 2013"
      expect(upload).to_not be_valid
    end

    it "correct seasons" do
      upload.description = "AGM 2013/14"
      expect(upload).to be_valid
      upload.description = "AGM 2014-2015"
      expect(upload).to be_valid
    end

    it "incorrect seasons" do
      upload.description = "Cork Open 2012-13"
      expect(upload).to_not be_valid
      upload.description = "Cork Open 2015/2016"
      expect(upload).to_not be_valid
    end
  end
end
