require 'spec_helper'

describe Episode do
  let(:articles) { 5.times.map { create(:article) } }
  let(:series)   { create(:series) }

  context "create" do
    it "no episodes" do
      expect(series.episodes).to be_empty
      expect(series.articles).to be_empty
    end

    it "one episode" do
      create(:episode, series: series, article: articles[0], number: 1)

      expect(series.episodes.size).to eq 1
      expect(series.articles.size).to eq 1

      expect(articles[0].episodes.size).to eq 1
      expect(articles[0].series.size).to eq 1
    end

    it "two episodes" do
      create(:episode, series: series, article: articles[0], number: 1)
      create(:episode, series: series, article: articles[1], number: 2)

      expect(series.episodes.size).to eq 2
      expect(series.episodes[0].number).to eq 1
      expect(series.episodes[1].number).to eq 2

      expect(series.articles.size).to eq 2
      expect(series.articles[0]).to eq articles[0]
      expect(series.articles[1]).to eq articles[1]

      expect(articles[0].episodes.size).to eq 1
      expect(articles[0].series.size).to eq 1

      expect(articles[1].episodes.size).to eq 1
      expect(articles[1].series.size).to eq 1
    end
  end

  context "numbers" do
    it "no number" do
      create(:episode, series: series, article: articles[0])
      series.reload

      expect(series.episodes.size).to eq 1
      expect(series.episodes[0].number).to eq 1

      create(:episode, series: series, article: articles[1])
      series.reload

      expect(series.episodes.size).to eq 2
      expect(series.episodes[0].number).to eq 1
      expect(series.episodes[1].number).to eq 2
      expect(series.articles[0]).to eq articles[0]
      expect(series.articles[1]).to eq articles[1]
    end

    it "large number" do
      create(:episode, series: series, article: articles[0], number: 10)
      series.reload

      expect(series.episodes.size).to eq 1
      expect(series.episodes[0].number).to eq 1

      create(:episode, series: series, article: articles[1], number: 99)
      series.reload

      expect(series.episodes.size).to eq 2
      expect(series.episodes[0].number).to eq 1
      expect(series.episodes[1].number).to eq 2
      expect(series.articles[0]).to eq articles[0]
      expect(series.articles[1]).to eq articles[1]
    end

    it "existing number" do
      create(:episode, series: series, article: articles[0], number: 1)
      create(:episode, series: series, article: articles[1], number: 1)
      series.reload

      expect(series.episodes.size).to eq 2
      expect(series.episodes[0].number).to eq 1
      expect(series.episodes[1].number).to eq 2

      expect(series.articles.size).to eq 2
      expect(series.articles[0]).to eq articles[1]
      expect(series.articles[1]).to eq articles[0]

      create(:episode, series: series, article: articles[2], number: 1)
      series.reload

      expect(series.episodes.size).to eq 3
      expect(series.episodes[0].number).to eq 1
      expect(series.episodes[1].number).to eq 2
      expect(series.episodes[2].number).to eq 3

      expect(series.articles.size).to eq 3
      expect(series.articles[0]).to eq articles[2]
      expect(series.articles[1]).to eq articles[1]
      expect(series.articles[2]).to eq articles[0]

      create(:episode, series: series, article: articles[3], number: 3)
      series.reload

      expect(series.episodes.size).to eq 4
      expect(series.episodes[0].number).to eq 1
      expect(series.episodes[1].number).to eq 2
      expect(series.episodes[2].number).to eq 3
      expect(series.episodes[3].number).to eq 4

      expect(series.articles.size).to eq 4
      expect(series.articles[0]).to eq articles[2]
      expect(series.articles[1]).to eq articles[1]
      expect(series.articles[2]).to eq articles[3]
      expect(series.articles[3]).to eq articles[0]

      create(:episode, series: series, article: articles[4], number: 2)
      series.reload

      expect(series.episodes.size).to eq 5
      expect(series.episodes[0].number).to eq 1
      expect(series.episodes[1].number).to eq 2
      expect(series.episodes[2].number).to eq 3
      expect(series.episodes[3].number).to eq 4
      expect(series.episodes[4].number).to eq 5

      expect(series.articles.size).to eq 5
      expect(series.articles[0]).to eq articles[2]
      expect(series.articles[1]).to eq articles[4]
      expect(series.articles[2]).to eq articles[1]
      expect(series.articles[3]).to eq articles[3]
      expect(series.articles[4]).to eq articles[0]
    end
  end

  context "destroy" do
    let!(:episodes) { 5.times.map { |i| create(:episode, series: series, article: articles[i], number: i + 1) } }

    it "numbers" do
      series.reload

      expect(series.episodes.size).to eq 5
      expect(series.episodes[0].number).to eq 1
      expect(series.episodes[1].number).to eq 2
      expect(series.episodes[2].number).to eq 3
      expect(series.episodes[3].number).to eq 4
      expect(series.episodes[4].number).to eq 5

      expect(series.articles.size).to eq 5
      expect(series.articles[0]).to eq articles[0]
      expect(series.articles[1]).to eq articles[1]
      expect(series.articles[2]).to eq articles[2]
      expect(series.articles[3]).to eq articles[3]
      expect(series.articles[4]).to eq articles[4]

      episodes[2].destroy
      series.reload

      expect(series.episodes.size).to eq 4
      expect(series.episodes[0].number).to eq 1
      expect(series.episodes[1].number).to eq 2
      expect(series.episodes[2].number).to eq 3
      expect(series.episodes[3].number).to eq 4

      expect(series.articles.size).to eq 4
      expect(series.articles[0]).to eq articles[0]
      expect(series.articles[1]).to eq articles[1]
      expect(series.articles[2]).to eq articles[3]
      expect(series.articles[3]).to eq articles[4]

      episodes[0].reload.destroy
      series.reload

      expect(series.episodes.size).to eq 3
      expect(series.episodes[0].number).to eq 1
      expect(series.episodes[1].number).to eq 2
      expect(series.episodes[2].number).to eq 3

      expect(series.articles.size).to eq 3
      expect(series.articles[0]).to eq articles[1]
      expect(series.articles[1]).to eq articles[3]
      expect(series.articles[2]).to eq articles[4]

      episodes[4].reload.destroy
      series.reload

      expect(series.episodes.size).to eq 2
      expect(series.episodes[0].number).to eq 1
      expect(series.episodes[1].number).to eq 2

      expect(series.articles.size).to eq 2
      expect(series.articles[0]).to eq articles[1]
      expect(series.articles[1]).to eq articles[3]

      episodes[1].reload.destroy
      series.reload

      expect(series.episodes.size).to eq 1
      expect(series.episodes[0].number).to eq 1

      expect(series.articles.size).to eq 1
      expect(series.articles[0]).to eq articles[3]

      episodes[3].reload
      episodes[3].destroy
      series.reload

      expect(series.episodes.size).to eq 0
      expect(series.articles.size).to eq 0
    end
  end

  context "destroy article" do
    let!(:episodes) { 3.times.map { |i| create(:episode, series: series, article: articles[i], number: i + 1) } }

    it "numbers" do
      series.reload

      expect(series.episodes.size).to eq 3
      expect(series.episodes[0].number).to eq 1
      expect(series.episodes[1].number).to eq 2
      expect(series.episodes[2].number).to eq 3

      expect(series.articles.size).to eq 3
      expect(series.articles[0]).to eq articles[0]
      expect(series.articles[1]).to eq articles[1]
      expect(series.articles[2]).to eq articles[2]

      articles[1].destroy
      series.reload

      expect(series.episodes.size).to eq 2
      expect(series.episodes[0].number).to eq 1
      expect(series.episodes[1].number).to eq 2

      expect(series.articles.size).to eq 2
      expect(series.articles[0]).to eq articles[0]
      expect(series.articles[1]).to eq articles[2]

      articles[0].destroy
      series.reload

      expect(series.episodes.size).to eq 1
      expect(series.episodes[0].number).to eq 1

      expect(series.articles.size).to eq 1
      expect(series.articles[0]).to eq articles[2]

      articles[2].destroy
      series.reload

      expect(series.episodes.size).to eq 0
      expect(series.articles.size).to eq 0
    end
  end

  context "article in more than one series" do
    let(:seires) { create(:series) }

    before(:each) do
      create(:episode, series: series, article: articles[0])
      create(:episode, series: series, article: articles[1])
      create(:episode, series: series, article: articles[2])
      create(:episode, series: seires, article: articles[2])
      create(:episode, series: seires, article: articles[3])
    end

    it "destroy the common one" do
      expect(articles[2].episodes.count).to eq 2
      expect(articles[2].series.count).to eq 2

      expect(Article.count).to eq 5
      expect(Episode.count).to eq 5

      expect(series.episodes.size).to eq 3
      expect(seires.episodes.size).to eq 2

      articles[2].destroy
      series.reload
      seires.reload

      expect(Article.count).to eq 4
      expect(Episode.count).to eq 3

      expect(series.episodes.size).to eq 2
      expect(seires.episodes.size).to eq 1
    end
  end
end
