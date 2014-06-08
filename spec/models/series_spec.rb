require 'spec_helper'

describe Series do
  let(:articles) { (0..3).each_with_object([]) { |n, a| a << create(:article) } }
  let(:series)   { create(:series) }

  context "destroy" do
    before(:each) do
      (0..3).each { |i| create(:episode, series: series, article: articles[i], number: i + 1) }
    end

    it "epiodes but not articles" do
      expect(Article.count).to eq 4
      expect(Episode.count).to eq 4
      expect(Series.count).to eq 1

      series.destroy

      expect(Article.count).to eq 4
      expect(Episode.count).to eq 0
      expect(Series.count).to eq 0
    end
  end
end
