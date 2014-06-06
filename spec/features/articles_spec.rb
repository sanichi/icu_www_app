require 'spec_helper'

describe Article do
  let(:access)     { I18n.t("access.access") }
  let(:adm_access) { I18n.t("access.admins") }
  let(:all_access) { I18n.t("access.all") }
  let(:edr_access) { I18n.t("access.editors") }
  let(:mem_access) { I18n.t("access.members") }
  let(:search)     { I18n.t("search") }

  context "access" do
    let!(:article_all) { create(:article, access: "all") }
    let!(:article_mem) { create(:article, access: "members") }
    let!(:article_edt) { create(:article, access: "editors") }
    let!(:article_adm) { create(:article, access: "admins") }

    let(:result_row)  { "tr.result" }
    let(:access_menu) { "//select[@name='access']" }

    def access_opt(text)
      "//select/option[.='#{text}']"
    end

    it "guests" do
      visit articles_path
      expect(page).to have_link(article_all.title)
      expect(page).to_not have_link(article_mem.title)
      expect(page).to_not have_link(article_edt.title)
      expect(page).to_not have_link(article_adm.title)
      expect(page).to have_css(result_row, count: 1)

      expect(page).to_not have_xpath(access_menu)
    end

    it "members" do
      login "member"
      visit articles_path
      expect(page).to have_link(article_all.title)
      expect(page).to have_link(article_mem.title)
      expect(page).to_not have_link(article_edt.title)
      expect(page).to_not have_link(article_adm.title)
      expect(page).to have_css(result_row, count: 2)

      expect(page).to have_xpath(access_menu)
      expect(page).to have_xpath(access_opt(all_access))
      expect(page).to have_xpath(access_opt(mem_access))
      expect(page).to_not have_xpath(access_opt(edr_access))
      expect(page).to_not have_xpath(access_opt(adm_access))

      select all_access, from: access
      click_button search
      expect(page).to have_link(article_all.title)
      expect(page).to have_css(result_row, count: 1)

      select mem_access, from: access
      click_button search
      expect(page).to have_link(article_mem.title)
      expect(page).to have_css(result_row, count: 1)
    end

    it "editors" do
      login "editor"
      visit articles_path
      expect(page).to have_link(article_all.title)
      expect(page).to have_link(article_mem.title)
      expect(page).to have_link(article_edt.title)
      expect(page).to_not have_link(article_adm.title)
      expect(page).to have_css(result_row, count: 3)

      expect(page).to have_xpath(access_menu)
      expect(page).to have_xpath(access_opt(all_access))
      expect(page).to have_xpath(access_opt(mem_access))
      expect(page).to have_xpath(access_opt(edr_access))
      expect(page).to_not have_xpath(access_opt(adm_access))

      select all_access, from: access
      click_button search
      expect(page).to have_link(article_all.title)
      expect(page).to have_css(result_row, count: 1)

      select mem_access, from: access
      click_button search
      expect(page).to have_link(article_mem.title)
      expect(page).to have_css(result_row, count: 1)

      select edr_access, from: access
      click_button search
      expect(page).to have_link(article_edt.title)
      expect(page).to have_css(result_row, count: 1)
    end

    it "admins" do
      login "admin"
      visit articles_path
      expect(page).to have_link(article_all.title)
      expect(page).to have_link(article_mem.title)
      expect(page).to have_link(article_edt.title)
      expect(page).to have_link(article_adm.title)
      expect(page).to have_css(result_row, count: 4)

      expect(page).to have_xpath(access_menu)
      expect(page).to have_xpath(access_opt(all_access))
      expect(page).to have_xpath(access_opt(mem_access))
      expect(page).to have_xpath(access_opt(edr_access))
      expect(page).to have_xpath(access_opt(adm_access))

      select all_access, from: access
      click_button search
      expect(page).to have_link(article_all.title)
      expect(page).to have_css(result_row, count: 1)

      select mem_access, from: access
      click_button search
      expect(page).to have_link(article_mem.title)
      expect(page).to have_css(result_row, count: 1)

      select edr_access, from: access
      click_button search
      expect(page).to have_link(article_edt.title)
      expect(page).to have_css(result_row, count: 1)

      select adm_access, from: access
      click_button search
      expect(page).to have_link(article_adm.title)
      expect(page).to have_css(result_row, count: 1)
    end
  end
end
