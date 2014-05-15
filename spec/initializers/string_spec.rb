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
    let(:before) { "<p>The <em>Daily Telegraph</em> <br/> or the <b>Times</b>.</p>" }
    let(:after)  { "The Daily Telegraph  or the Times." }

    it "#markoff" do
      expect(before.markoff).to eq after
      expect(before).to_not eq after
    end

    it "#markoff!" do
      expect(before.markoff!).to eq after
      expect(before).to eq after
    end
  end
end
