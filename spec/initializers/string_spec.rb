require 'spec_helper'

describe String do
  context "trimming" do
    let(:before) { "  Mark   J.\n\t L.  \r\n  Orr    \n" }
    let(:after)  { "Mark J. L. Orr" }

    it "#trim" do
      expect(before.trim).to eq after
      expect(before).to_not eq after
    end

    it "#trim!" do
      expect(before.trim!).to eq after
      expect(before).to eq after
    end
  end

  context "removing markup" do
    it "#markoff and #markoff!" do
      before = "<p>The <em>Daily Telegraph</em> <br/> or the <b>Times</b>.</p>"
      after = "The Daily Telegraph  or the Times."
      expect(before.markoff).to eq after
      expect(before).to_not eq after
      expect(before.markoff!).to eq after
      expect(before).to eq after
    end

    it "with attributes" do
      before = "<table style=\"margin-left:0\">\n<tr align=\"center\">\n<td>Lee-Orr</td>\n</tr>\n</table>"
      after = "\n\nLee-Orr\n\n"
      expect(before.markoff).to eq after
    end
  end

  context "ICU markup" do
    it "articles" do
      before = "[ART:123:Futher details]."
      after = '<a href="/articles/123">Futher details</a>.'
      expect(before.icu_markup).to eq after
      expect(before).to_not eq after
    end

    it "games" do
      before = "[PGN:22669:Lee,C. 0-1 Orr,M.]"
      after = '<a href="/games/22669">Lee,C. 0-1 Orr,M.</a>'
      expect(before.icu_markup).to eq after
      expect(before).to_not eq after
    end

    it "image links" do
      before = "[IML:456:Picture]"
      after = '<a href="/images/456">Picture</a>'
      expect(before.icu_markup).to eq after
      expect(before).to_not eq after
    end

    it "tournaments" do
      before = "Tournament [TRN:1:table]"
      after = 'Tournament <a href="/tournaments/1">table</a>'
      expect(before.icu_markup).to eq after
      expect(before).to_not eq after
    end

    it "uploads" do
      before = "Click [UPL:7890:here] to download."
      after = 'Click <a href="/uploads/7890">here</a> to download.'
      expect(before.icu_markup).to eq after
      expect(before).to_not eq after
    end

    it "multiple" do
      before = "[IML:234:picture] or [UPL:3456:PDF] or [PGN:21723:½-½]."
      after = '<a href="/images/234">picture</a> or <a href="/uploads/3456">PDF</a> or <a href="/games/21723">½-½</a>.'
      expect(before.icu_markup).to eq after
      expect(before).to_not eq after
    end
  end
end
