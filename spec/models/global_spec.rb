require 'rails_helper'

describe Global do
  context "#valid_email?" do
    it "nil" do
      expect(Global.valid_email?(nil)).to be false
    end

    it "rubbish" do
      expect(Global.valid_email?("rubbish")).to be false
    end

    it "missing local part" do
      expect(Global.valid_email?("@markorr.net")).to be false
    end

    it "missing domain part" do
      expect(Global.valid_email?("mark")).to be false
    end

    it "success" do
      expect(Global.valid_email?("mark@markorr.net")).to be true
    end
  end

  context "#valid_url?" do
    it "nil" do
      expect(Global.valid_url?(nil)).to be false
    end

    it "rubbish" do
      expect(Global.valid_url?("rubbish")).to be false
    end

    it "missing scheme" do
      expect(Global.valid_url?("markorr.net")).to be false
    end

    it "missing slash" do
      expect(Global.valid_url?("https:/markorr.net")).to be false
    end

    it "wrong type of slashes" do
      expect(Global.valid_url?("https:\\\\markorr.net")).to be false
    end

    it "success" do
      expect(Global.valid_url?("http://markorr.net")).to be true
      expect(Global.valid_url?("https://markorr.net")).to be true
    end
  end
end
