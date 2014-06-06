require 'spec_helper'

describe Upload do
  let(:access)     { I18n.t("access.access") }
  let(:adm_access) { I18n.t("access.admins") }
  let(:all_access) { I18n.t("access.all") }
  let(:edr_access) { I18n.t("access.editors") }
  let(:mem_access) { I18n.t("access.members") }
  let(:search)     { I18n.t("search") }

  context "access" do
    let!(:upload_all) { create(:upload, access: "all") }
    let!(:upload_mem) { create(:upload, access: "members") }
    let!(:upload_edt) { create(:upload, access: "editors") }
    let!(:upload_adm) { create(:upload, access: "admins") }

    let(:url_all)     { "a[href='#{upload_all.url}']" }
    let(:url_mem)     { "a[href='#{upload_mem.url}']" }
    let(:url_edt)     { "a[href='#{upload_edt.url}']" }
    let(:url_adm)     { "a[href='#{upload_adm.url}']" }

    let(:result_row)  { "tr.result" }
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
      expect(page).to have_css(result_row, count: 1)

      expect(page).to_not have_xpath(access_menu)
    end

    it "members" do
      login "member"
      visit uploads_path
      expect(page).to have_css(url_all)
      expect(page).to have_css(url_mem)
      expect(page).to_not have_css(url_edt)
      expect(page).to_not have_css(url_adm)
      expect(page).to have_css(result_row, count: 2)

      expect(page).to have_xpath(access_menu)
      expect(page).to have_xpath(access_opt(all_access))
      expect(page).to have_xpath(access_opt(mem_access))
      expect(page).to_not have_xpath(access_opt(edr_access))
      expect(page).to_not have_xpath(access_opt(adm_access))

      select all_access, from: access
      click_button search
      expect(page).to have_css(url_all)
      expect(page).to have_css(result_row, count: 1)

      select mem_access, from: access
      click_button search
      expect(page).to have_css(url_mem)
      expect(page).to have_css(result_row, count: 1)
    end

    it "editors" do
      login "editor"
      visit uploads_path
      expect(page).to have_css(url_all)
      expect(page).to have_css(url_mem)
      expect(page).to have_css(url_edt)
      expect(page).to_not have_css(url_adm)
      expect(page).to have_css(result_row, count: 3)

      expect(page).to have_xpath(access_menu)
      expect(page).to have_xpath(access_opt(all_access))
      expect(page).to have_xpath(access_opt(mem_access))
      expect(page).to have_xpath(access_opt(edr_access))
      expect(page).to_not have_xpath(access_opt(adm_access))

      select all_access, from: access
      click_button search
      expect(page).to have_css(url_all)
      expect(page).to have_css(result_row, count: 1)

      select mem_access, from: access
      click_button search
      expect(page).to have_css(url_mem)
      expect(page).to have_css(result_row, count: 1)

      select edr_access, from: access
      click_button search
      expect(page).to have_css(url_edt)
      expect(page).to have_css(result_row, count: 1)
    end

    it "admins" do
      login "admin"
      visit uploads_path
      expect(page).to have_css(url_all)
      expect(page).to have_css(url_mem)
      expect(page).to have_css(url_edt)
      expect(page).to have_css(url_adm)
      expect(page).to have_css(result_row, count: 4)

      expect(page).to have_xpath(access_menu)
      expect(page).to have_xpath(access_opt(all_access))
      expect(page).to have_xpath(access_opt(mem_access))
      expect(page).to have_xpath(access_opt(edr_access))
      expect(page).to have_xpath(access_opt(adm_access))

      select all_access, from: access
      click_button search
      expect(page).to have_css(url_all)
      expect(page).to have_css(result_row, count: 1)

      select mem_access, from: access
      click_button search
      expect(page).to have_css(url_mem)
      expect(page).to have_css(result_row, count: 1)

      select edr_access, from: access
      click_button search
      expect(page).to have_css(url_edt)
      expect(page).to have_css(result_row, count: 1)

      select adm_access, from: access
      click_button search
      expect(page).to have_css(url_adm)
      expect(page).to have_css(result_row, count: 1)
    end
  end
end
