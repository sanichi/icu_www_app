require 'rails_helper'

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
      before = "<p>The <em>Daily Telegraph</em> <br/> or the <B>Times</B>.</p>"
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

  context "obscuring" do
    it "#rot13" do
      expect("".rot13).to eq ""
      expect("Shpx gur fcnzzref".rot13).to eq "Fuck the spammers"
      expect("Fuck the spammers".rot13).to eq "Shpx gur fcnzzref"
      expect("!1@2£3$4%5^6&7*8(9)0_-+=").to eq "!1@2£3$4%5^6&7*8(9)0_-+="
      expect("<span>42</span>".rot13).to eq "<fcna>42</fcna>"
    end

    it "#obscure" do
      expect(%q{<a href="mailto:joe@bloggs.ie">joe@bloggs.ie</a>}.obscure).to eq %q{'vr<\057n>', 'vr">wbr\100oybttf', '<n uers="znvygb:wbr\100oybttf'}
      expect(%q{<a href="mailto:m@markorr.com">M. O'Orr</a>}.obscure).to eq %q{' B\'Bee<\057n>', 'pbz">Z', '<n uers="znvygb:z\100znexbee'}

    end
  end
end
