require 'spec_helper'

describe Ireland do
  it "::provinces" do
    expect(Ireland.provinces.join("|")).to eq "connaught|leinster|munster|ulster"
  end

  it "::counties" do
    expect(Ireland.counties).to have(32).counties
    expect(Ireland.counties.join).to eq Ireland.counties.sort.join
    expect(Ireland.counties(nil)).to have(32).counties
    expect(Ireland.counties(:connaught)).to have(5).counties
    expect(Ireland.counties("leinster")).to have(12).counties
    expect(Ireland.counties(:munster)).to have(6).counties
    expect(Ireland.counties("ulster")).to have(9).counties
    expect(Ireland.counties("scotland")).to have(0).counties
    expect(Ireland.counties("")).to have(0).counties
  end

  it "::county?" do
    expect(Ireland.county?("down")).to be_true
    expect(Ireland.county?(:galway)).to be_true
    expect(Ireland.county?("leinster")).to be_false
    expect(Ireland.county?("")).to be_false
    expect(Ireland.county?(nil)).to be_false
  end

  it "::province?" do
    expect(Ireland.province?("munster")).to be_true
    expect(Ireland.province?(:ulster)).to be_true
    expect(Ireland.province?("dublin")).to be_false
    expect(Ireland.province?("")).to be_false
    expect(Ireland.province?(nil)).to be_false
  end

  it "::has?" do
    expect(Ireland.has?(:connaught, "sligo")).to be_true
    expect(Ireland.has?("leinster", "dublin")).to be_true
    expect(Ireland.has?("munster", :cork)).to be_true
    expect(Ireland.has?(:ulster, :down)).to be_true
    expect(Ireland.has?(:connaught, :offaly)).to be_false
    expect(Ireland.has?(:leinster, :armagh)).to be_false
    expect(Ireland.has?(:munster, :kilkenny)).to be_false
    expect(Ireland.has?(:ulster, :leitrim)).to be_false
    expect(Ireland.has?(:ulster, :lothians)).to be_false
    expect(Ireland.has?("wales", "glamorgan")).to be_false
    expect(Ireland.has?("", "")).to be_false
    expect(Ireland.has?(nil, nil)).to be_false
  end

  it "::province" do
    expect(Ireland.province("down")).to eq "ulster"
    expect(Ireland.province(:galway)).to eq "connaught"
    expect(Ireland.province("dublin")).to eq "leinster"
    expect(Ireland.province(:cork)).to eq "munster"
    expect(Ireland.province("london")).to be_nil
    expect(Ireland.province("")).to be_nil
    expect(Ireland.province(nil)).to be_nil
  end
end
