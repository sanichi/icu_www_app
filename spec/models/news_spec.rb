require 'rails_helper'

describe News do
  context "#html" do
    let(:news)   { create(:news_extra) }
    let!(:event) { create(:event, id: 98) }

    it "various substitutions" do
      str = news.html
      expect(str).to match "Täby, Sweden"
      expect(str).to match "<h4>Galway Blitz</h4>"
      expect(str).to match %q{John Alfred&#39;s}
      expect(str).to match %q{working on it &#9786;.}
      expect(str).to match %q{<a href="http://www.scandinavian-chess.se/index.asp">Ladies Open</a>}
      expect(str).to match %q{<a href="/events/98">monthly rapidplay</a>}
      expect(str).to match /Entries to me via <script>liame\([^)]+\)<\/script>/
    end
  end
end
