require 'rails_helper'

describe Download do;
  include_context "features"

  let(:access)        { I18n.t("access.access") }
  let(:adm_access)    { I18n.t("access.#{admins}") }
  let(:all_access)    { I18n.t("access.#{everyone}") }
  let(:edr_access)    { I18n.t("access.#{editors}") }
  let(:mem_access)    { I18n.t("access.#{members}") }

  let(:admins)        { "admins" }
  let(:editors)       { "editors" }
  let(:everyone)      { "all" }
  let(:members)       { "members" }

  let(:download_dir)    { Rails.root + "spec/files/downloads/" }
  let(:image_dir)     { Rails.root + "spec/files/images/" }

  def expect_data(download, file, size, type)
    expect(download.data_file_name).to eq file
    expect(download.data_file_size).to eq size
    expect(download.data_content_type).to eq type
  end

  def expect_pdf(download)
    expect_data(download, "CT-4000.pdf", 143005, "application/pdf")
  end

  def expect_pgn(download)
    expect_data(download, "CT-4000.pgn", 24540, "application/x-chess-pgn")
  end

  def expect_doc(download)
    expect_data(download, "minutes_2004.doc", 67584, "application/msword")
  end

  def expect_unobfuscated(download)
    dir = Pathname.new(download.data.path).dirname
    expect(File.directory?(dir)).to be true
    expect(File.file?(dir + download.data_file_name)).to be true
    expect(download.url.include?(download.data_file_name)).to be true
    expect(download.data.url.include?(download.data_file_name)).to be false
  end

  def expect_obfuscated(download)
    dir = Pathname.new(download.data.path).dirname
    expect(File.directory?(dir)).to be true
    expect(File.file?(dir + download.data_file_name)).to be false
    expect(download.url.include?(download.data_file_name)).to be false
    expect(download.data.url.include?(download.data_file_name)).to be false
  end

  context "authorization" do
    let(:level1)  { ["admin", user] }
    let(:level2)  { ["editor"] }
    let(:level3)  { User::ROLES.reject { |r| level1.include?(r) || level2.include?(r) }.append("guest") }
    let!(:download) { create(:download, user: user) }
    let(:user)    { create(:user, roles: "editor") }

    def cell(label)
      "//th[.='#{label}']/following-sibling::td"
    end

    it "level 1 can update and delete as well as create and show" do
      level1.each do |role|
        login role
        visit new_admin_download_path
        expect(page).to_not have_css(failure)
        visit edit_admin_download_path(download)
        expect(page).to_not have_css(failure)
        visit downloads_path
        click_link download.description
        expect(page).to have_xpath(cell(description), text: download.description)
        expect(page).to have_link(edit)
        expect(page).to have_link(delete)
      end
    end

    it "level 2 can't update or delete" do
      level2.each do |role|
        login role
        visit new_admin_download_path
        expect(page).to_not have_css(failure)
        visit edit_admin_download_path(download)
        expect(page).to have_css(failure, text: unauthorized)
        visit downloads_path
        click_link download.description
        expect(page).to have_xpath(cell(description), text: download.description)
        expect(page).to_not have_link(edit)
        expect(page).to_not have_link(delete)
      end
    end

    it "level 3 can only index" do
      level3.each do |role|
        login role
        visit new_admin_download_path
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_download_path(download)
        expect(page).to have_css(failure, text: unauthorized)
        visit admin_download_path(download)
        expect(page).to have_css(failure, text: unauthorized)
        visit downloads_path
        expect(page).to_not have_link(download.description)
        expect(page).to have_text(download.description)
      end
    end
  end

  context "accessibility" do
    let(:all)          { create(:download, access: everyone) }
    let(:members_only) { create(:download, access: members) }
    let(:editors_only) { create(:download, access: editors) }
    let(:admins_only)  { create(:download, access: admins) }

    it "guest" do
      logout
      [all].each do |download|
        visit download_path(download)
        expect(page).to_not have_css(failure)
      end
      [members_only, editors_only, admins_only].each do |download|
        visit download_path(download)
        expect(page).to have_css(failure, text: unauthorized)
      end
    end

    it "member" do
      login
      [all, members_only].each do |download|
        visit download_path(download)
        expect(page).to_not have_css(failure)
      end
      [editors_only, admins_only].each do |download|
        visit download_path(download)
        expect(page).to have_css(failure, text: unauthorized)
      end
    end

    it "editor" do
      login "editor"
      [all, members_only, editors_only].each do |download|
        visit download_path(download)
        expect(page).to_not have_css(failure)
      end
      [admins_only].each do |download|
        visit download_path(download)
        expect(page).to have_css(failure, text: unauthorized)
      end
    end

    it "admin" do
      login "admin"
      [all, members_only, editors_only, admins_only].each do |download|
        visit download_path(download)
        expect(page).to_not have_css(failure)
      end
    end
  end

  context "create" do
    let(:pdf_download_file) { "CT-4000.pdf" }
    let(:pdf_desc_text)   { "Chess Today #4000" }
    let(:pdf_year_text)   { "2011" }
    let(:pgn_download_file) { "CT-4000.pgn" }
    let(:pgn_desc_text)   { "Chess Today #4000 Games" }
    let(:pgn_year_text)   { "2011" }

    before(:each) do
      @user = login "editor"
      visit new_admin_download_path
    end

    it "PDF (all)" do
      fill_in description, with: pdf_desc_text
      fill_in year, with: pdf_year_text
      select all_access, from: access
      attach_file file, download_dir + pdf_download_file
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Download.count).to eq 1
      download = Download.first

      expect(download.description).to eq pdf_desc_text
      expect(download.year).to eq pdf_year_text.to_i
      expect(download.access).to eq everyone
      expect(download.user_id).to eq @user.id
      expect_pdf(download)

      expect_unobfuscated(download)
    end

    it "PGN (members only)" do
      fill_in description, with: pgn_desc_text
      fill_in year, with: pgn_year_text
      select mem_access, from: access
      attach_file file, download_dir + pgn_download_file
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Download.count).to eq 1
      download = Download.first

      expect(download.description).to eq pgn_desc_text
      expect(download.year).to eq pgn_year_text.to_i
      expect(download.access).to eq members
      expect(download.user_id).to eq @user.id
      expect_pgn(download)

      expect_obfuscated(download)
    end

    it "invalid type" do
      fill_in description, with: "April"
      fill_in year, with: "1986"
      select all_access, from: access
      attach_file file, image_dir + "april.jpeg"
      click_button save

      expect(page).to_not have_css(success)
      expect(page).to have_css(field_error, text: "invalid")
      expect(Download.count).to eq 0
    end
  end

  context "edit" do
    let(:user)     { create(:user, roles: "editor") }
    let(:download)   { create(:download, user: user) }
    let(:alt_desc) { "ICU AGM Minutes" }
    let(:alt_file) { "minutes_2004.doc" }
    let(:alt_year) { "2004" }
    let(:new_desc) { "Chess Today #4000 games" }
    let(:new_file) { "CT-4000.pgn" }
    let(:new_year) { "2014" }
    let(:old_desc) { download.description }
    let(:old_year) { download.year }
    let(:old_acsy) { download.access }
    let(:option)   { "select option" }

    before(:each) do
      login user
      visit admin_download_path(download)
      click_link edit
    end

    it "file data" do
      attach_file file, download_dir + new_file
      click_button save

      expect(page).to have_css(success, text: updated)
      download.reload

      expect(download.description).to eq old_desc
      expect(download.year).to eq old_year
      expect(download.access).to eq old_acsy
      expect_pgn(download)

      expect_unobfuscated(download)
    end

    it "meta data" do
      fill_in description, with: new_desc
      fill_in year, with: new_year
      select edr_access, from: access
      click_button save

      expect(page).to have_css(success, text: updated)
      download.reload

      expect(download.description).to eq new_desc
      expect(download.year).to eq new_year.to_i
      expect(download.access).to eq editors
      expect_pdf(download)

      expect_obfuscated(download)
    end

    it "just access" do
      expect(page).to have_css(option, text: edr_access)
      expect(page).to_not have_css(option, text: adm_access)

      login "admin"
      visit admin_download_path(download)
      click_link edit
      select adm_access, from: access
      click_button save

      download.reload
      expect(download.access).to eq admins
      expect_obfuscated(download)

      click_link edit
      select mem_access, from: access
      click_button save

      download.reload
      expect(download.access).to eq members
      expect_obfuscated(download)

      click_link edit
      select all_access, from: access
      click_button save

      download.reload
      expect(download.access).to eq everyone
      expect_unobfuscated(download)
    end

    it "all data" do
      fill_in description, with: alt_desc
      fill_in year, with: alt_year
      select mem_access, from: access
      attach_file file, download_dir + alt_file
      click_button save

      expect(page).to have_css(success, text: updated)
      download.reload

      expect(download.description).to eq alt_desc
      expect(download.year).to eq alt_year.to_i
      expect(download.access).to eq members
      expect_doc(download)

      expect_obfuscated(download)
    end
  end

  context "delete" do
    let(:user)      { create(:user, roles: "editor") }
    let(:download)    { create(:download, user: user) }
    let(:directory) { Pathname.new(download.data.path).dirname.to_s }

    it "by owner" do
      expect(File.directory?(directory)).to be true
      login user
      visit admin_download_path(download)
      click_link delete

      expect(page).to have_css(success, text: deleted)
      expect(Download.count).to be 0
      expect(File.exist?(directory)).to be false
    end

    it "by non-owner" do
      login "editor"
      visit admin_download_path(download)
      expect(page).to_not have_link(delete)
    end
  end
end
