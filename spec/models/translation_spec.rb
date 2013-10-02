# encoding: utf-8
require 'spec_helper'

describe Translation do
  context "::update_db" do
    before(:all) do
      @count = Translation.yaml_data.size
    end

    it "initialize an empty table" do
      Translation.update_db
      expect(Translation.count).to eq(@count)
      expect(Translation.where(value: nil, active: true, user: nil).count).to eq(@count)
    end

    it "update a partly filled table" do
      @t = {}
      @t[:to_inactive]         = FactoryGirl.create(:translation, key: "foo.bar", value: "barra", english: "bar")
      @t[:already_inactive]    = FactoryGirl.create(:translation, key: "foo.baz", value: "base", english: "baz", active: false)
      @t[:no_change]           = FactoryGirl.create(:translation, key: "edit", value: "Cuir", english: "Edit")
      @t[:to_update_no_val]    = FactoryGirl.create(:translation, key: "save", value: nil, english: "Store", user: nil)
      @t[:to_update_with_val]  = FactoryGirl.create(:translation, key: "user.role.admin", value: "Riarthóir", english: "God")
      @t[:to_active]           = FactoryGirl.create(:translation, key: "user.role.editor", value: "Eagarthóir", english: "Editor", active: false)
      @t[:translation_missing] = FactoryGirl.create(:translation, key: "user.role.treasurer", value: nil, english: "Treasurer", user: nil)
      Translation.update_db
      expect(Translation.count).to eq(@count + 2)
      expect(Translation.where(active: true).count).to eq(@count)
      expect(Translation.where(active: false).count).to eq(2)
      expect(Translation.where(active: true).where("english != old_english").count).to eq(2)
      expect(Translation.where(value: nil, active: true, user: nil).count).to eq(@count - 3)
      @t.each_value { |t| t.reload }
      expect(@t[:to_inactive].active).to be_false
      expect(@t[:already_inactive].active).to be_false
      expect(@t[:to_active].active).to be_true
      expect(@t[:to_update_no_val].english).to eq("Save")
      expect(@t[:to_update_no_val].old_english).to eq("Store")
      expect(@t[:to_update_with_val].english).to eq("Administrator")
      expect(@t[:to_update_with_val].old_english).to eq("God")
    end
  end

  context "::yaml_data" do
    it "should process yaml files without an exception" do
      hash = nil
      expect { hash = Translation.yaml_data }.to_not raise_exception
      expect(hash).to be_a(Hash)
      expect(hash.size).to be > 45
      hash.each_pair do |k,v|
        expect(k).to match(Translation::KEY_FORMAT)
        expect(v).to be_present
        expect(v).to match(Translation::VAL_FORMAT)
      end
    end
  end

  context "translations" do
    it "English translations provided by YAML files" do
      expect(I18n.t("edit", locale: :en)).to eq("Edit")
      expect(I18n.t("session.invalid_email", locale: :en)).to eq("Invalid email or password")
    end

    it "revert to English if there isn't an Irish translation" do
      expect(I18n.t("edit", locale: :ga)).to eq("Edit")
      expect(I18n.t("session.invalid_email", locale: :ga)).to eq("Invalid email or password")
    end

    it "throw an exception in the test environment for missing translations" do
      expect { I18n.t("not.here", locale: :en) }.to raise_exception(/translation missing/)
      expect { I18n.t("not.here", locale: :ga) }.to raise_exception(/translation missing/)
    end

    it "Irish translations provided by database" do
      edit = "Cuir"
      invalid = "R-phost neamhbhailí nó ar do phasfhocal"
      FactoryGirl.create(:translation, key: "edit", value: edit, english: "Edit")
      FactoryGirl.create(:translation, key: "session.invalid_email", value: invalid, english: "Invalid email or password")
      expect(I18n.t("edit", locale: "ga")).to eq(edit)
      expect(I18n.t("session.invalid_email", locale: "ga")).to eq(invalid)
    end
  end

  context "backend key store API" do
    before(:each) do
      FactoryGirl.create(:translation, key: "user.role.admin", value: "Riarthóir", english: "Administrator")
      FactoryGirl.create(:translation, key: "user.role.editor", value: "Eagarthóir", english: "Editor")
      FactoryGirl.create(:translation, key: "pagination.prev", value: "roimhe seo", english: "previous")
      FactoryGirl.create(:translation, key: "session.enter_email", value: "Cuir isteach r-phost", english: "Please enter an email", old_english: "Not the same")
      FactoryGirl.create(:translation, key: "old.unused", value: "Sean", english: "Old", active: false)
      FactoryGirl.create(:translation, key: "not.yet.set", value: nil, english: "New")
    end

    it "#[]" do
      expect(Translation["ga.user.role.admin"]).to eq('"Riarthóir"')
      expect(Translation["ga.old.unused"]).to be_nil
      expect(Translation["ga.not.yet.set"]).to be_nil
      expect(Translation["ga.not.there.yet"]).to be_nil
      expect(Translation["invalid key"]).to be_nil
    end

    it "#[]=" do
      # note that in our case, this method does nothing, but it is defined as it's part of the API
      expect { Translation["ga.user.role.treasurer"] = "Cisteoir" }.to_not raise_exception
    end

    it "#keys" do
      expect(Translation.keys.join(" ")).to eq("ga.pagination.prev ga.session.enter_email ga.user.role.admin ga.user.role.editor")
    end
  end
end
