require 'rails_helper'

describe Util::Diff do
  def diff(a, b, *opts)
    Util::Diff.new(a, b).difference(*opts)
  end

  it "short strings" do
    a, b = diff("Mark", "Malcolm")
    expect(a).to eq "Mark"
    expect(b).to eq "Malcolm"
    a, b = diff("Mark", "Mark")
    expect(a).to eq "Mark"
    expect(b).to eq "Mark"
  end

  it "unequal long strings" do
    a, b = diff("Abcdefghijklmnopqrstuvwxyz", "abcdefghijklmnopqrstuvwxyz", 10, 5)
    expect(a).to eq "Abcdefg..."
    expect(b).to eq "abcdefg..."
    a, b = diff("abCdefghijklmnopqrstuvwxyz", "abcdefghijklmnopqrstuvwxyz", 10, 5)
    expect(a).to eq "abCdefg..."
    expect(b).to eq "abcdefg..."
    a, b = diff("abcdefgHijklmnopqrstuvwxyz", "abcdefghijklmnopqrstuvwxyz", 10, 5)
    expect(a).to eq "..cdefg..."
    expect(b).to eq "..cdefg..."
    a, b = diff("abcdefghijklMnopqrstuvwxyz", "abcdefghijklmnopqrstuvwxyz", 10, 5)
    expect(a).to eq "...hijk..."
    expect(b).to eq "...hijk..."
    a, b = diff("abcdefghijklmnopqrs", "abcdefghijklmnopqrstuvwxyz", 10, 5)
    expect(a).to eq "...opqrs"
    expect(b).to eq "...opqr..."
    a, b = diff("abcdefghijklmnopqrstuvwxyz", "abcdefghijklmnopqrstuvwxyz", 10, 5)
    expect(a).to eq "abcdefg..."
    expect(b).to eq "abcdefg..."
  end

  it "integers" do
    a, b = diff(1, 2)
    expect(a).to eq "1"
    expect(b).to eq "2"
  end

  it "dates" do
    a, b = diff(Date.new(2013, 10, 13), Date.new(2013, 11, 13))
    expect(a).to eq "2013-10-13"
    expect(b).to eq "2013-11-13"
  end

  it "datetimes" do
    a, b = diff(DateTime.new(2013, 10, 13, 22, 10, 40), DateTime.new(2013, 10, 13, 12, 20, 50))
    expect(a).to eq "2013-10-13 22:10:40"
    expect(b).to eq "2013-10-13 12:20:50"
    a, b = diff(DateTime.new(2013, 10, 13, 22, 10, 40), DateTime.new(2013, 10, 13, 12, 20, 50), 13, 3)
    expect(a).to eq "...13 22:1..."
    expect(b).to eq "...13 12:2..."
  end
end
