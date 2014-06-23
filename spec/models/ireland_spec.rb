require 'rails_helper'

describe Ireland do
  it "::provinces" do
    expect(Ireland.provinces.join("|")).to eq "connaught|leinster|munster|ulster"
  end

  it "::counties" do
    expect(Ireland.counties.size).to eq 32
    expect(Ireland.counties.join).to eq Ireland.counties.sort.join
    expect(Ireland.counties(nil).size).to eq 32
    expect(Ireland.counties(:connaught).size).to eq 5
    expect(Ireland.counties("leinster").size).to eq 12
    expect(Ireland.counties(:munster).size).to eq 6
    expect(Ireland.counties("ulster").size).to eq 9
    expect(Ireland.counties("scotland").size).to eq 0
    expect(Ireland.counties("").size).to eq 0
  end

  it "::county?" do
    expect(Ireland.county?("down")).to be true
    expect(Ireland.county?(:galway)).to be true
    expect(Ireland.county?("leinster")).to be false
    expect(Ireland.county?("")).to be false
    expect(Ireland.county?(nil)).to be false
  end

  it "::province?" do
    expect(Ireland.province?("munster")).to be true
    expect(Ireland.province?(:ulster)).to be true
    expect(Ireland.province?("dublin")).to be false
    expect(Ireland.province?("")).to be false
    expect(Ireland.province?(nil)).to be false
  end

  it "::has?" do
    expect(Ireland.has?(:connaught, "sligo")).to be true
    expect(Ireland.has?("leinster", "dublin")).to be true
    expect(Ireland.has?("munster", :cork)).to be true
    expect(Ireland.has?(:ulster, :down)).to be true
    expect(Ireland.has?(:connaught, :offaly)).to be false
    expect(Ireland.has?(:leinster, :armagh)).to be false
    expect(Ireland.has?(:munster, :kilkenny)).to be false
    expect(Ireland.has?(:ulster, :leitrim)).to be false
    expect(Ireland.has?(:ulster, :lothians)).to be false
    expect(Ireland.has?("wales", "glamorgan")).to be false
    expect(Ireland.has?("", "")).to be false
    expect(Ireland.has?(nil, nil)).to be false
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
