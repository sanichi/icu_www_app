require 'spec_helper'

describe Series do;
  include_context "features"

  let(:article_title) { I18n.t("article.title") }
  let(:series_title)  { I18n.t("article.series.title") }

  def select_button(index, max=0)
    "#select_article_button_#{index + max}"
  end

  context "authorization" do
    let!(:header)  { "h1" }
    let(:level1)   { %w[admin editor] }
    let(:level2)   { User::ROLES.reject { |r| level1.include?(r) }.append("guest") }
    let!(:series)  { create(:series) }

    it "level 1 can manage" do
      level1.each do |role|
        login role
        visit new_admin_series_path
        expect(page).to_not have_css(failure)
        visit edit_admin_series_path(series)
        expect(page).to_not have_css(failure)
        visit series_index_path
        click_link series.title
        expect(page).to have_css(header, text: series.title)
        expect(page).to have_link(edit)
        expect(page).to have_link(delete)
      end
    end

    it "level 2 can only index and show" do
      level2.each do |role|
        login role
        visit new_admin_series_path
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_series_path(series)
        expect(page).to have_css(failure, text: unauthorized)
        visit series_index_path
        click_link series.title
        expect(page).to have_css(header, text: series.title)
        expect(page).to_not have_link(edit)
        expect(page).to_not have_link(delete)
      end
    end
  end

  context "create", js: true do
    let(:title) { "My Beautiful Series" }
    let(:more)  { "＋" }

    let!(:articles) { (1..4).each_with_object([]) { |n, a| a << create(:article) } }
    let(:user)      { create(:user, roles: "editor") }

    before(:each) do
      login user
      visit new_admin_series_path
    end

    it "no articles" do
      fill_in series_title, with: title
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Episode.count).to eq 0
      expect(Series.count).to eq 1
      series = Series.first

      expect(series.title).to eq title
      expect(series.episodes).to be_empty
      expect(series.articles).to be_empty
      expect(series.max_number).to eq 0

      expect(JournalEntry.series.count).to eq 1
      expect(JournalEntry.series.where(action: "create", by: user.signature, journalable_id: series.id).count).to eq 1
    end

    it "two articles" do
      fill_in series_title, with: title

      find(select_button(1)).click
      fill_in article_title, with: articles[0].title + force_submit
      click_link articles[0].title

      wait_a_second

      find(select_button(2)).click
      fill_in article_title, with: articles[1].title + force_submit
      click_link articles[1].title

      wait_a_second
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Episode.count).to eq 2
      expect(Series.count).to eq 1
      series = Series.first

      expect(series.title).to eq title
      expect(series.episodes.map(&:number).join("|")).to eq "1|2"
      expect(series.articles.map(&:title).join("|")).to eq (0..1).map{ |i| articles[i].title }.join("|")
      expect(series.max_number).to eq 2

      expect(JournalEntry.series.count).to eq 1
      expect(JournalEntry.series.where(action: "create", by: user.signature, journalable_id: series.id).count).to eq 1
    end

    it "more than two" do
      fill_in series_title, with: title

      find(select_button(1)).click
      fill_in article_title, with: articles[0].title + force_submit
      click_link articles[0].title

      wait_a_second

      find(select_button(2)).click
      fill_in article_title, with: articles[1].title + force_submit
      click_link articles[1].title

      wait_a_second

      expect(page).to_not have_css(select_button(3))
      click_link(more)

      find(select_button(3)).click
      fill_in article_title, with: articles[2].title + force_submit
      click_link articles[2].title

      wait_a_second

      expect(page).to_not have_css(select_button(4))
      click_link(more)

      find(select_button(4)).click
      fill_in article_title, with: articles[3].title + force_submit
      click_link articles[3].title

      wait_a_second

      click_button save

      expect(page).to have_css(success, text: created)
      expect(Episode.count).to eq 4
      expect(Series.count).to eq 1
      series = Series.first

      expect(series.title).to eq title
      expect(series.episodes.map(&:number).join("|")).to eq "1|2|3|4"
      expect(series.articles.map(&:title).join("|")).to eq (0..3).map{ |i| articles[i].title }.join("|")
      expect(series.max_number).to eq 4

      expect(JournalEntry.series.count).to eq 1
      expect(JournalEntry.series.where(action: "create", by: user.signature, journalable_id: series.id).count).to eq 1
    end
  end

  context "edit", js: true do
    let!(:episodes) { (1..3).each_with_object([]) { |n, a| a << create(:episode, series: series) } }
    let!(:article)  { create(:article) }
    let(:series)    { create(:series) }
    let(:user)      { create(:user, roles: "editor") }

    def keep(n)
      "#keep_#{n}"
    end

    def number(index, max=0)
      "#num_#{index + max}"
    end

    before(:each) do
      login user
      visit series_path(series)
      click_link edit
    end

    it "title" do
      new_title = "New Series Title"
      fill_in series_title, with: new_title
      click_button save

      series.reload
      expect(series.title).to eq new_title
      expect(series.episodes.count).to eq 3
      expect(series.articles.count).to eq 3

      expect(JournalEntry.series.count).to eq 1
      expect(JournalEntry.series.where(action: "update", by: user.signature, journalable_id: series.id, column: "title").count).to eq 1
    end

    it "add article in last position" do
      find(select_button(1, 3)).click
      fill_in article_title, with: article.title + force_submit
      click_link article.title

      wait_a_second

      click_button save

      series.reload
      expect(series.episodes.count).to eq 4
      expect(series.articles.count).to eq 4
      expect(series.episodes.map(&:number).join("|")).to eq "1|2|3|4"
      expect(series.articles.map(&:title).join("|")).to eq (0..2).map{ |i| episodes[i].article.title }.push(article.title).join("|")

      expect(Article.count).to eq 4
      expect(Episode.count).to eq 4
      expect(Series.count).to eq 1
      expect(JournalEntry.series.count).to eq 0
    end

    it "remove article" do
      find(keep(2)).set(false)

      click_button save

      series.reload
      expect(series.episodes.count).to eq 2
      expect(series.articles.count).to eq 2
      expect(series.episodes.map(&:number).join("|")).to eq "1|2"
      expect(series.articles.map(&:title).join("|")).to eq [0, 2].map{ |i| episodes[i].article.title }.join("|")

      expect(Article.count).to eq 4
      expect(Episode.count).to eq 2
      expect(Series.count).to eq 1
      expect(JournalEntry.series.count).to eq 0
    end

    it "move first article to last position" do
      find(keep(1)).set(false)

      find(select_button(1, 3)).click
      fill_in article_title, with: episodes[0].article.title + force_submit
      click_link episodes[0].article.title

      wait_a_second

      click_button save

      series.reload
      expect(series.episodes.count).to eq 3
      expect(series.articles.count).to eq 3
      expect(series.episodes.map(&:number).join("|")).to eq "1|2|3"
      expect(series.articles.map(&:title).join("|")).to eq [1, 2, 0].map{ |i| episodes[i].article.title }.join("|")

      expect(Article.count).to eq 4
      expect(Episode.count).to eq 3
      expect(Series.count).to eq 1
      expect(JournalEntry.series.count).to eq 0
    end

    it "move last article to first position" do
      find(keep(3)).set(false)

      find(select_button(1, 3)).click
      fill_in article_title, with: episodes[2].article.title + force_submit
      click_link episodes[2].article.title

      wait_a_second

      find(number(1, 3)).select(1)
      click_button save

      series.reload
      expect(series.episodes.count).to eq 3
      expect(series.articles.count).to eq 3
      expect(series.episodes.map(&:number).join("|")).to eq "1|2|3"
      expect(series.articles.map(&:title).join("|")).to eq [2, 0, 1].map{ |i| episodes[i].article.title }.join("|")

      expect(Article.count).to eq 4
      expect(Episode.count).to eq 3
      expect(Series.count).to eq 1
      expect(JournalEntry.series.count).to eq 0
    end
  end

  context "delete" do
    let!(:episodes) { 3.times.each_with_object([]) { |n, a| a << create(:episode, series: series) } }
    let(:series)    { create(:series) }
    let(:user)      { create(:user, roles: "editor") }

    before(:each) do
      login user
      visit series_path(series)
    end

    it "destroy" do
      expect(Article.count).to eq 3
      expect(Episode.count).to eq 3
      expect(Series.count).to eq 1
      expect(JournalEntry.series.count).to eq 0

      click_link delete
      expect(page).to have_css(success, text: deleted)

      expect(Article.count).to eq 3
      expect(Episode.count).to eq 0
      expect(Series.count).to be 0
      expect(JournalEntry.series.where(action: "destroy", by: user.signature, journalable_id: series.id).count).to eq 1
    end
  end
end
