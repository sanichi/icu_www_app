require 'spec_helper'

describe Article do;
  include_context "features"

  let(:access_menu)   { I18n.t("access.access") }
  let(:author_input)  { I18n.t("article.author") }
  let(:category_menu) { I18n.t("article.category.category") }
  let(:text_text)     { I18n.t("article.text") }
  let(:title_input)   { I18n.t("article.title") }
  let(:year_input)    { I18n.t("year") }

  context "authorization" do
    let!(:article) { create(:article, user: user) }
    let!(:header)  { "h1" }
    let(:level1)   { ["admin", user] }
    let(:level2)   { ["editor"] }
    let(:level3)   { User::ROLES.reject { |r| level1.include?(r) || level2.include?(r) }.append("guest") }
    let(:user)     { create(:user, roles: "editor") }

    it "level 1 can update and delete as well as create and show" do
      level1.each do |role|
        login role
        visit new_admin_article_path
        expect(page).to_not have_css(failure)
        visit edit_admin_article_path(article)
        expect(page).to_not have_css(failure)
        visit articles_path
        click_link article.title
        expect(page).to have_css(header, text: article.title)
        expect(page).to have_link(edit)
        expect(page).to have_link(delete)
      end
    end

    it "level 2 can't update or delete" do
      level2.each do |role|
        login role
        visit new_admin_article_path
        expect(page).to_not have_css(failure)
        visit edit_admin_article_path(article)
        expect(page).to have_css(failure, text: unauthorized)
        visit articles_path
        click_link article.title
        expect(page).to have_css(header, text: article.title)
        expect(page).to_not have_link(edit)
        expect(page).to_not have_link(delete)
      end
    end

    it "level 3 can only index and show" do
      level3.each do |role|
        login role
        visit new_admin_article_path
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_article_path(article)
        expect(page).to have_css(failure, text: unauthorized)
        visit articles_path
        click_link article.title
        expect(page).to have_css(header, text: article.title)
        expect(page).to_not have_link(edit)
        expect(page).to_not have_link(delete)
      end
    end
  end

  context "accessibility" do
    let(:all)          { create(:article, access: "all") }
    let(:members_only) { create(:article, access: "members") }
    let(:editors_only) { create(:article, access: "editors") }
    let(:admins_only)  { create(:article, access: "admins") }

    it "guest" do
      logout
      [all].each do |article|
        visit article_path(article)
        expect(page).to_not have_css(failure)
      end
      [members_only, editors_only, admins_only].each do |article|
        visit article_path(article)
        expect(page).to have_css(failure, text: unauthorized)
      end
    end

    it "member" do
      login
      [all, members_only].each do |article|
        visit article_path(article)
        expect(page).to_not have_css(failure)
      end
      [editors_only, admins_only].each do |article|
        visit article_path(article)
        expect(page).to have_css(failure, text: unauthorized)
      end
    end

    it "editor" do
      login "editor"
      [all, members_only, editors_only].each do |article|
        visit article_path(article)
        expect(page).to_not have_css(failure)
      end
      [admins_only].each do |article|
        visit article_path(article)
        expect(page).to have_css(failure, text: unauthorized)
      end
    end

    it "admin" do
      login "admin"
      [all, members_only, editors_only, admins_only].each do |article|
        visit article_path(article)
        expect(page).to_not have_css(failure)
      end
    end
  end

  context "create" do
    let(:user) { create(:user, roles: "editor") }

    before(:each) do
      login user
      visit new_admin_article_path
    end

    it "everyone, active" do
      access = "all"
      author = "Anthony Penrose"
      category = "bulletin"
      text = "Lee Miller, fashion model, photographer, war correspondent, writer.\n\nA paradox of irascibility and effusive warmth."
      title = "The Lives of Lee Miller"
      year = 2014

      fill_in title_input, with: title
      fill_in year_input, with: year
      fill_in author_input, with: author
      fill_in text_text, with: text
      select I18n.t("article.category.#{category}"), from: category_menu
      select I18n.t("access.#{access}"), from: access_menu
      check active
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Article.count).to eq 1
      article = Article.first

      expect(article.access).to eq access
      expect(article.active).to be_true
      expect(article.author).to eq author
      expect(article.category).to eq category
      expect(article.text).to eq text
      expect(article.title).to eq title
      expect(article.user_id).to eq user.id
      expect(article.year).to eq year

      expect(JournalEntry.articles.where(action: "create", by: user.signature, journalable_id: article.id).count).to eq 1
    end
  end

  context "edit" do
    let(:adm_access) { I18n.t("access.admins") }
    let(:all_access) { I18n.t("access.all") }
    let(:edr_access) { I18n.t("access.editors") }
    let(:mem_access) { I18n.t("access.members") }

    let(:option)   { "select option" }

    let(:article)  { create(:article, user: user) }
    let(:user)     { create(:user, roles: "editor") }

    before(:each) do
      login user
      visit article_path(article)
      click_link edit
    end

    it "title" do
      new_title = "New Title"
      fill_in title_input, with: new_title
      click_button save

      expect(page).to have_css(success, text: updated)
      article.reload
      expect(article.title).to eq new_title

      expect(JournalEntry.articles.where(action: "update", by: user.signature, journalable_id: article.id).count).to eq 1
    end

    it "access" do
      expect(page).to have_css(option, text: edr_access)
      expect(page).to_not have_css(option, text: adm_access)

      login "admin"
      visit article_path(article)

      click_link edit
      select adm_access, from: access_menu
      click_button save

      article.reload
      expect(article.access).to eq "admins"

      click_link edit
      select edr_access, from: access_menu
      click_button save

      article.reload
      expect(article.access).to eq "editors"

      click_link edit
      select mem_access, from: access_menu
      click_button save

      article.reload
      expect(article.access).to eq "members"

      click_link edit
      select all_access, from: access_menu
      click_button save

      article.reload
      expect(article.access).to eq "all"

      expect(JournalEntry.articles.where(action: "update", journalable_id: article.id).count).to eq 4
    end
  end

  context "delete" do
    let(:user)    { create(:user, roles: "editor") }
    let(:article) { create(:article, user: user) }

    it "destroy" do
      login user
      visit article_path(article)
      click_link delete
      expect(page).to have_css(success, text: deleted)

      expect(Article.count).to be 0
      expect(JournalEntry.articles.where(action: "destroy", by: user.signature, journalable_id: article.id).count).to eq 1
    end
  end
end
