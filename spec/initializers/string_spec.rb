require 'spec_helper'

describe String do
  let(:raw)  { "  Mark   J.\n\t L.  \r\n  Orr    \n"}
  let(:neat) { "Mark J. L. Orr"}

  it "#trim" do
    expect(raw.trim).to eq neat
    expect(raw).to_not eq neat
  end

  it "#trim!" do
    expect(raw.trim!).to eq neat
    expect(raw).to eq neat
  end
end
