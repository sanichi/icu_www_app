require 'spec_helper'

describe Translation do
  context "::update_db" do
    before(:all) do
      @count = Translation.yaml_data.size
    end

    it "initialize an empty table" do
      Translation.update_db
      expect(Translation.count).to eq @count
      expect(Translation.where(value: nil, active: true, user: nil).count).to eq @count
      expect(Translation.creatable.count).to eq @count
      expect(Translation.updatable.count).to eq 0
      expect(Translation.deletable.count).to eq 0
      expect(Translation.editable.count).to eq 0
    end

    it "update a partly filled table" do
      @t = {}
      @t[:to_inactive]         = create(:translation, key: "foo.bar", value: "barra", english: "bar")
      @t[:already_inactive]    = create(:translation, key: "foo.baz", value: "base", english: "baz", active: false)
      @t[:no_change]           = create(:translation, key: "edit", value: "Cuir", english: "Edit")
      @t[:to_update_no_val]    = create(:translation, key: "save", value: nil, english: "Store", user: nil)
      @t[:to_update_with_val]  = create(:translation, key: "user.role.admin", value: "Riarthóir", english: "God")
      @t[:to_active]           = create(:translation, key: "user.role.editor", value: "Eagarthóir", english: "Editor", active: false)
      @t[:translation_missing] = create(:translation, key: "user.role.treasurer", value: nil, english: "Treasurer", user: nil)
      Translation.update_db
      expect(Translation.count).to eq @count + 2
      expect(Translation.where(active: true).count).to eq @count
      expect(Translation.where(active: false).count).to eq 2
      expect(Translation.where(active: true).where("english != old_english").count).to eq 2
      expect(Translation.where(value: nil, active: true, user: nil).count).to eq @count - 3
      @t.each_value { |t| t.reload }
      expect(@t[:to_inactive].active).to be_false
      expect(@t[:already_inactive].active).to be_false
      expect(@t[:to_active].active).to be_true
      expect(@t[:to_update_no_val].english).to eq "Save"
      expect(@t[:to_update_no_val].old_english).to eq "Store"
      expect(@t[:to_update_with_val].english).to eq "Administrator"
      expect(@t[:to_update_with_val].old_english).to eq "God"
      expect(Translation.creatable.count).to eq @count - 3
      expect(Translation.updatable.count).to eq 1
      expect(Translation.deletable.count).to eq 2
      expect(Translation.editable.count).to eq 2
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
    after(:each) do
      Translation.cache.flushdb
    end

    it "English translations provided by YAML files" do
      expect(I18n.t("edit", locale: :en)).to eq "Edit"
      expect(I18n.t("session.invalid_email", locale: :en)).to eq "Invalid email or password"
    end

    it "revert to English if there isn't an Irish translation" do
      expect(I18n.t("edit", locale: :ga)).to eq "Edit"
      expect(I18n.t("session.invalid_email", locale: :ga)).to eq "Invalid email or password"
    end

    it "throw an exception in the test environment for missing translations" do
      expect { I18n.t("not.here", locale: :en) }.to raise_exception(/translation missing/)
      expect { I18n.t("not.here", locale: :ga) }.to raise_exception(/translation missing/)
    end

    it "Irish translations provided by Redis via database updates" do
      edit = "Cuir"
      invalid = "R-phost neamhbhailí nó ar do phasfhocal"
      create(:translation, key: "edit", value: edit, english: "Edit")
      create(:translation, key: "session.invalid_email", value: invalid, english: "Invalid email or password")
      expect(I18n.t("edit", locale: "ga")).to eq edit
      expect(I18n.t("session.invalid_email", locale: "ga")).to eq invalid
    end
  end

  context "cache" do
    before(:each) do
      @count = Translation.yaml_data.size
      @cache = Translation.cache
    end

    after(:each) do
      @cache.flushdb
    end

    def cached
      @cache.keys.sort.map{ |k| "#{k}:#{@cache.get(k)}" }.join("|")
    end

    it "is empty for a database with no tanslations" do
      expect(Translation.count).to eq 0
      expect(Translation.check_cache(dont_skip_test_env: true)).to eq 0
      expect(cached).to eq ""
    end

    it "is empty for a database with no active tanslations" do
      Translation.update_db
      expect(Translation.count).to eq @count
      expect(Translation.check_cache(dont_skip_test_env: true)).to eq 0
      expect(cached).to eq ""
    end

    it "is non-empty if there are active translations" do
      create(:translation, key: "cancel", english: "Cancel", value: "Cealaigh")
      create(:translation, key: "delete", english: "Cancel", value: nil)
      create(:translation, key: "user.role.translator", english: "Translator", value: "Aistritheoir")
      create(:translation, key: "user.role.admin", english: "Administrator", old_english: "God", value: "Dia")
      create(:translation, key: "not.used", english: "not used", value: "nach n-úsáidtear", active: false)
      expect(Translation.count).to eq 5
      @cache.flushdb # reset the cache before calling check_cache for this test
      expect(Translation.check_cache(dont_skip_test_env: true)).to eq 3
      expect(cached).to eq 'ga.cancel:"Cealaigh"|ga.user.role.admin:"Dia"|ga.user.role.translator:"Aistritheoir"'
    end

    it "is affected by creating, updating or deleting translations" do
      expect(cached).to eq ""

      cancel = create(:translation, key: "cancel", english: "Cancel", value: "Cealaigh")
      expect(cached).to eq 'ga.cancel:"Cealaigh"'

      admin = create(:translation, key: "user.role.admin", english: "Administrator", old_english: "God", value: "Dia")
      expect(cached).to eq 'ga.cancel:"Cealaigh"|ga.user.role.admin:"Dia"'

      create(:translation, key: "not.used", english: "not used", value: "nach n-úsáidtear", active: false)
      expect(cached).to eq 'ga.cancel:"Cealaigh"|ga.user.role.admin:"Dia"'

      create(:translation, key: "delete", english: "Cancel", value: nil)
      expect(cached).to eq 'ga.cancel:"Cealaigh"|ga.user.role.admin:"Dia"'

      admin.value = "Riarthóir"
      admin.old_english = "Administrator"
      admin.save
      expect(cached).to eq 'ga.cancel:"Cealaigh"|ga.user.role.admin:"Riarthóir"'

      cancel.active = false
      cancel.save
      expect(cached).to eq 'ga.user.role.admin:"Riarthóir"'

      admin.destroy
      expect(cached).to eq ""
    end
  end
end
