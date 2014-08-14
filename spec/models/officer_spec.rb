require 'rails_helper'

describe Officer do
  context "normalisation" do
    it "emails" do
      officer = create(:officer, emails: " mark@apple.com   mark@fide.com")
      expect(officer.emails).to eq "mark@apple.com mark@fide.com"
    end
  end

  context "defaults" do
    it "emails" do
      expect(create(:officer, role: "ratings").emails).to eq "ratings@icu.ie"
      expect(create(:officer, role: "fide_ecu").emails).to eq "fide@icu.ie ecu@icu.ie"
    end
  end

  context "validation" do
    let(:params) { FactoryGirl.attributes_for(:officer) }

    it "factory defaults" do
      expect(build(:officer, params)).to be_valid
    end

    it "emails" do
      expect(build(:officer, params.merge(emails: "ratings.icu.ie"))).to_not be_valid
      expect(build(:officer, params.merge(emails: "ratings@icu.ie webmaster"))).to_not be_valid
      expect(build(:officer, params.merge(emails: "ratings@icu.ie webmaster@icu.ie"))).to be_valid
    end
  end
end
