require 'spec_helper'

describe Upload do
  let(:access)        { I18n.t("access.access") }
  let(:admins_text)   { I18n.t("access.#{admins}") }
  let(:everyone_text) { I18n.t("access.#{everyone}") }
  let(:editors_text)  { I18n.t("access.#{editors}") }
  let(:delete)        { I18n.t("delete") }
  let(:description)   { I18n.t("description") }
  let(:edit)          { I18n.t("edit") }
  let(:file)          { I18n.t("file") }
  let(:members_text)  { I18n.t("access.#{members}") }
  let(:save)          { I18n.t("save") }
  let(:search)        { I18n.t("search") }
  let(:unauthorized)  { I18n.t("errors.alerts.unauthorized") }
  let(:year)          { I18n.t("year") }

  let(:admins)        { "admins" }
  let(:editors)       { "editors" }
  let(:everyone)      { "all" }
  let(:members)       { "members" }

  let(:failure)       { "div.alert-danger" }
  let(:field_error)   { "div.help-block" }
  let(:success)       { "div.alert-success" }
  let(:success_text)  { "successfully created" }

  let(:upload_dir)    { Rails.root + "spec/files/uploads/" }
  let(:image_dir)     { Rails.root + "spec/files/images/" }

  def expect_data(upload, file, size, type)
    expect(upload.data_file_name).to eq file
    expect(upload.data_file_size).to eq size
    expect(upload.data_content_type).to eq type
  end

  def expect_pdf(upload)
    expect_data(upload, "CT-4000.pdf", 143005, "application/pdf")
  end

  def expect_pgn(upload)
    expect_data(upload, "CT-4000.pgn", 24540, "application/x-chess-pgn")
  end

  def expect_doc(upload)
    expect_data(upload, "minutes_2004.doc", 67584, "application/msword")
  end

  def expect_unobfuscated(upload)
    dir = Pathname.new(upload.data.path).dirname
    expect(File.directory?(dir)).to be_true
    expect(File.file?(dir + upload.data_file_name)).to be_true
    expect(upload.url.include?(upload.data_file_name)).to be_true
    expect(upload.data.url.include?(upload.data_file_name)).to be_false
  end

  def expect_obfuscated(upload)
    dir = Pathname.new(upload.data.path).dirname
    expect(File.directory?(dir)).to be_true
    expect(File.file?(dir + upload.data_file_name)).to be_false
    expect(upload.url.include?(upload.data_file_name)).to be_false
    expect(upload.data.url.include?(upload.data_file_name)).to be_false
  end

  context "authorization" do
    let(:level1)  { ["admin", user] }
    let(:level2)  { ["editor"] }
    let(:level3)  { User::ROLES.reject { |r| r == "admin" || r == "editor" }.append("guest") }
    let!(:upload) { create(:upload, user: user) }
    let(:user)    { create(:user, roles: "editor") }

    def cell(label)
      "//th[.='#{label}']/following-sibling::td"
    end

    it "admin and the owner can update and delete as well as create and show" do
      level1.each do |role|
        login role
        visit new_admin_upload_path
        expect(page).to_not have_css(failure)
        visit edit_admin_upload_path(upload)
        expect(page).to_not have_css(failure)
        visit uploads_path
        click_link upload.description
        expect(page).to have_xpath(cell(description), text: upload.description)
        expect(page).to have_link(edit)
        expect(page).to have_link(delete)
      end
    end

    it "editors can't update or delete other editor's uploads" do
      level2.each do |role|
        login role
        visit new_admin_upload_path
        expect(page).to_not have_css(failure)
        visit edit_admin_upload_path(upload)
        expect(page).to have_css(failure)
        visit uploads_path
        click_link upload.description
        expect(page).to have_xpath(cell(description), text: upload.description)
        expect(page).to_not have_link(edit)
        expect(page).to_not have_link(delete)
      end
    end

    it "other roles and guests can only index" do
      level3.each do |role|
        login role
        visit new_admin_upload_path
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_upload_path(upload)
        expect(page).to have_css(failure, text: unauthorized)
        visit admin_upload_path(upload)
        expect(page).to have_css(failure, text: unauthorized)
        visit uploads_path
        expect(page).to_not have_link(upload.description)
        expect(page).to have_text(upload.description)
      end
    end
  end

  context "accessibility" do
    let(:all)          { create(:upload, access: "all") }
    let(:members_only) { create(:upload, access: "members") }
    let(:editors_only) { create(:upload, access: "editors") }
    let(:admins_only)  { create(:upload, access: "admins") }

    it "guest" do
      logout
      [all].each do |upload|
        visit upload_path(upload)
        expect(page).to_not have_css(failure)
      end
      [members_only, editors_only, admins_only].each do |upload|
        visit upload_path(upload)
        expect(page).to have_css(failure, text: unauthorized)
      end
    end

    it "member" do
      login
      [all, members_only].each do |upload|
        visit upload_path(upload)
        expect(page).to_not have_css(failure)
      end
      [editors_only, admins_only].each do |upload|
        visit upload_path(upload)
        expect(page).to have_css(failure, text: unauthorized)
      end
    end

    it "editor" do
      login "editor"
      [all, members_only, editors_only].each do |upload|
        visit upload_path(upload)
        expect(page).to_not have_css(failure)
      end
      [admins_only].each do |upload|
        visit upload_path(upload)
        expect(page).to have_css(failure, text: unauthorized)
      end
    end

    it "admin" do
      login "admin"
      [all, members_only, editors_only, admins_only].each do |upload|
        visit upload_path(upload)
        expect(page).to_not have_css(failure)
      end
    end
  end

  context "create" do
    let(:pdf_upload_file) { "CT-4000.pdf" }
    let(:pdf_desc_text)   { "Chess Today #4000" }
    let(:pdf_year_text)   { "2011" }
    let(:pgn_upload_file) { "CT-4000.pgn" }
    let(:pgn_desc_text)   { "Chess Today #4000 Games" }
    let(:pgn_year_text)   { "2011" }

    before(:each) do
      @user = login "editor"
      visit new_admin_upload_path
    end

    it "PDF (all)" do
      fill_in description, with: pdf_desc_text
      fill_in year, with: pdf_year_text
      select everyone_text, from: access
      attach_file file, upload_dir + pdf_upload_file
      click_button save

      expect(page).to have_css(success, text: success_text)
      expect(Upload.count).to eq 1
      upload = Upload.first

      expect(upload.description).to eq pdf_desc_text
      expect(upload.year).to eq pdf_year_text.to_i
      expect(upload.access).to eq everyone
      expect(upload.user_id).to eq @user.id
      expect_pdf(upload)

      expect_unobfuscated(upload)
    end

    it "PGN (members only)" do
      fill_in description, with: pgn_desc_text
      fill_in year, with: pgn_year_text
      select members_text, from: access
      attach_file file, upload_dir + pgn_upload_file
      click_button save

      expect(page).to have_css(success, text: success_text)
      expect(Upload.count).to eq 1
      upload = Upload.first

      expect(upload.description).to eq pgn_desc_text
      expect(upload.year).to eq pgn_year_text.to_i
      expect(upload.access).to eq members
      expect(upload.user_id).to eq @user.id
      expect_pgn(upload)

      expect_obfuscated(upload)
    end

    it "invalid type" do
      fill_in description, with: "April"
      fill_in year, with: "1986"
      select everyone_text, from: access
      attach_file file, image_dir + "april.jpeg"
      click_button save

      expect(page).to_not have_css(success)
      expect(page).to have_css(field_error, text: "invalid")
      expect(Upload.count).to eq 0
    end
  end

  context "edit" do
    let(:user)     { create(:user, roles: "editor") }
    let(:upload)   { create(:upload, user: user) }
    let(:alt_desc) { "ICU AGM Minutes" }
    let(:alt_file) { "minutes_2004.doc" }
    let(:alt_year) { "2004" }
    let(:new_desc) { "Chess Today #4000 games" }
    let(:new_file) { "CT-4000.pgn" }
    let(:new_year) { "2014" }
    let(:old_desc) { upload.description }
    let(:old_year) { upload.year }
    let(:old_acsy) { upload.access }
    let(:option)   { "select option" }

    before(:each) do
      login user
      visit admin_upload_path(upload)
      click_link edit
    end

    it "file data" do
      attach_file file, upload_dir + new_file
      click_button save

      upload.reload
      expect(upload.description).to eq old_desc
      expect(upload.year).to eq old_year
      expect(upload.access).to eq old_acsy
      expect_pgn(upload)

      expect_unobfuscated(upload)
    end

    it "meta data" do
      fill_in description, with: new_desc
      fill_in year, with: new_year
      select editors_text, from: access
      click_button save

      upload.reload
      expect(upload.description).to eq new_desc
      expect(upload.year).to eq new_year.to_i
      expect(upload.access).to eq editors
      expect_pdf(upload)

      expect_obfuscated(upload)
    end

    it "just access" do
      expect(page).to have_css(option, text: editors_text)
      expect(page).to_not have_css(option, text: admins_text)

      login "admin"
      visit admin_upload_path(upload)
      click_link edit
      select admins_text, from: access
      click_button save

      upload.reload
      expect(upload.access).to eq admins
      expect_obfuscated(upload)

      click_link edit
      select members_text, from: access
      click_button save

      upload.reload
      expect(upload.access).to eq members
      expect_obfuscated(upload)

      click_link edit
      select everyone_text, from: access
      click_button save

      upload.reload
      expect(upload.access).to eq everyone
      expect_unobfuscated(upload)
    end

    it "all data" do
      fill_in description, with: alt_desc
      fill_in year, with: alt_year
      select members_text, from: access
      attach_file file, upload_dir + alt_file
      click_button save

      upload.reload
      expect(upload.description).to eq alt_desc
      expect(upload.year).to eq alt_year.to_i
      expect(upload.access).to eq members
      expect_doc(upload)

      expect_obfuscated(upload)
    end
  end

  context "delete" do
    let(:user)      { create(:user, roles: "editor") }
    let(:upload)    { create(:upload, user: user) }
    let(:directory) { Pathname.new(upload.data.path).dirname.to_s }

    it "by owner" do
      expect(File.directory?(directory)).to be_true
      login user
      visit admin_upload_path(upload)
      click_link delete
      expect(Upload.count).to be 0
      expect(File.exist?(directory)).to be_false
    end

    it "by non-owner" do
      login "editor"
      visit admin_upload_path(upload)
      expect(page).to_not have_link(delete)
    end
  end

  context "access" do
    let!(:upload_all) { create(:upload, access: everyone) }
    let!(:upload_mem) { create(:upload, access: members) }
    let!(:upload_edt) { create(:upload, access: editors) }
    let!(:upload_adm) { create(:upload, access: admins) }

    let(:url_all)     { "a[href='#{upload_all.url}']" }
    let(:url_mem)     { "a[href='#{upload_mem.url}']" }
    let(:url_edt)     { "a[href='#{upload_edt.url}']" }
    let(:url_adm)     { "a[href='#{upload_adm.url}']" }

    let(:desc_cell)   { "//tr/td/following-sibling::td[.='#{upload_all.description}']" }
    let(:access_menu) { "//select[@name='access']" }

    def access_opt(text)
      "//select/option[.='#{text}']"
    end

    it "guests" do
      visit uploads_path
      expect(page).to have_css(url_all)
      expect(page).to_not have_css(url_mem)
      expect(page).to_not have_css(url_edt)
      expect(page).to_not have_css(url_adm)
      expect(page).to have_xpath(desc_cell, count: 1)

      expect(page).to_not have_xpath(access_menu)
    end

    it "members" do
      login "member"
      visit uploads_path
      expect(page).to have_css(url_all)
      expect(page).to have_css(url_mem)
      expect(page).to_not have_css(url_edt)
      expect(page).to_not have_css(url_adm)
      expect(page).to have_xpath(desc_cell, count: 2)

      expect(page).to have_xpath(access_menu)
      expect(page).to have_xpath(access_opt(everyone_text))
      expect(page).to have_xpath(access_opt(members_text))
      expect(page).to_not have_xpath(access_opt(editors_text))
      expect(page).to_not have_xpath(access_opt(admins_text))

      select everyone_text, from: access
      click_button search
      expect(page).to have_css(url_all)
      expect(page).to have_xpath(desc_cell, count: 1)

      select members_text, from: access
      click_button search
      expect(page).to have_css(url_mem)
      expect(page).to have_xpath(desc_cell, count: 1)
    end

    it "editors" do
      login "editor"
      visit uploads_path
      expect(page).to have_css(url_all)
      expect(page).to have_css(url_mem)
      expect(page).to have_css(url_edt)
      expect(page).to_not have_css(url_adm)
      expect(page).to have_xpath(desc_cell, count: 3)

      expect(page).to have_xpath(access_menu)
      expect(page).to have_xpath(access_opt(everyone_text))
      expect(page).to have_xpath(access_opt(members_text))
      expect(page).to have_xpath(access_opt(editors_text))
      expect(page).to_not have_xpath(access_opt(admins_text))

      select everyone_text, from: access
      click_button search
      expect(page).to have_css(url_all)
      expect(page).to have_xpath(desc_cell, count: 1)

      select members_text, from: access
      click_button search
      expect(page).to have_css(url_mem)
      expect(page).to have_xpath(desc_cell, count: 1)

      select editors_text, from: access
      click_button search
      expect(page).to have_css(url_edt)
      expect(page).to have_xpath(desc_cell, count: 1)
    end

    it "admins" do
      login "admin"
      visit uploads_path
      expect(page).to have_css(url_all)
      expect(page).to have_css(url_mem)
      expect(page).to have_css(url_edt)
      expect(page).to have_css(url_adm)
      expect(page).to have_xpath(desc_cell, count: 4)

      expect(page).to have_xpath(access_menu)
      expect(page).to have_xpath(access_opt(everyone_text))
      expect(page).to have_xpath(access_opt(members_text))
      expect(page).to have_xpath(access_opt(editors_text))
      expect(page).to have_xpath(access_opt(admins_text))

      select everyone_text, from: access
      click_button search
      expect(page).to have_css(url_all)
      expect(page).to have_xpath(desc_cell, count: 1)

      select members_text, from: access
      click_button search
      expect(page).to have_css(url_mem)
      expect(page).to have_xpath(desc_cell, count: 1)

      select editors_text, from: access
      click_button search
      expect(page).to have_css(url_edt)
      expect(page).to have_xpath(desc_cell, count: 1)

      select admins_text, from: access
      click_button search
      expect(page).to have_css(url_adm)
      expect(page).to have_xpath(desc_cell, count: 1)
    end
  end
end
