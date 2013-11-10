require 'spec_helper'

describe Phone do
  context "parsed" do
    let(:array) { [] }
    let(:int_code) { array[0] }
    let(:local_code) { array[1] }
    let(:number) { array[2] }
    let(:mobile) { array[3] }
    let(:canonical) { array[4] }

    context "dublin" do
      let(:array) { ["353", "1", "2449745", false, "(01) 2449745"] }

      [
        "(00)(353)(01) 2449745",
        "00 353 01 244 9745",
        "00353 01 2449745",
        "+353 01 244 9745",
        "(01) 244 9745",
        "(0)1 244 9745",
        "01 244 9745",
        "01-2449745",
        "012449745",
        "12449745",
      ].each do |str|
        it "#{str}" do
          p = Phone.new(str)
          expect(p).to be_parsed
          expect(p.int_code).to eq int_code
          expect(p.local_code).to eq local_code
          expect(p.number).to eq number
          expect(p.mobile?).to eq mobile
          expect(p.canonical).to eq canonical
        end
      end
    end

    context "non-dublin" do
      let(:array) { ["353", "43", "35921", false, "(043) 35921"] }

      [
        "043 35921",
        "043-35921",
        "04335921",
        "4335921",
      ].each do |str|
        it "#{str}" do
          p = Phone.new(str)
          expect(p).to be_parsed
          expect(p.int_code).to eq int_code
          expect(p.local_code).to eq local_code
          expect(p.number).to eq number
          expect(p.mobile?).to eq mobile
          expect(p.canonical).to eq canonical
        end
      end
    end

    context "mobile" do
      let(:array) { ["353", "87", "2388673", true, "(087) 2388673"] }

      [
        "00353-087-2388673",
        "+353 87 2388673",
        "+353 872388673",
        "(087) 2388673",
        "872388673",
      ].each do |str|
        it "#{str}" do
          p = Phone.new(str)
          expect(p).to be_parsed
          expect(p.int_code).to eq int_code
          expect(p.local_code).to eq local_code
          expect(p.number).to eq number
          expect(p.mobile?).to eq mobile
          expect(p.canonical).to eq canonical
        end
      end
    end

    context "uk mobile" do
      let(:array) { ["44", "7968", "537010", true, "+44 7968 537010"] }

      [
        "(00)44(0)7968 537010",
        "+44 7968537010",
        "+44 796 8537010",
        "+44 79685 37010",
      ].each do |str|
        it "#{str}" do
          p = Phone.new(str)
          expect(p).to be_parsed
          expect(p.int_code).to eq int_code
          expect(p.local_code).to eq local_code
          expect(p.number).to eq number
          expect(p.mobile?).to eq mobile
          expect(p.canonical).to eq canonical
        end
      end
    end

    context "uk number" do
      let(:array) { ["44", "131", "5539051", false, "+44 131 5539051"] }

      [
        "(00)44 0131 5539051",
        "00 44 131 5539051",
        "+44 131 553 9051",
      ].each do |str|
        it "#{str}" do
          p = Phone.new(str)
          expect(p).to be_parsed
          expect(p.int_code).to eq int_code
          expect(p.local_code).to eq local_code
          expect(p.number).to eq number
          expect(p.mobile?).to eq mobile
          expect(p.canonical).to eq canonical
        end
      end
    end

    context "recover from bad input" do
      let(:array) { ["353", "91", "794849", false, "(091) 794849"] }

      [
        "(091) 794849 Father of 6695",
        "(091) 794849 (065) 6842035",
      ].each do |str|
        it "#{str}" do
          p = Phone.new(str)
          expect(p).to be_parsed
          expect(p.int_code).to eq int_code
          expect(p.local_code).to eq local_code
          expect(p.number).to eq number
          expect(p.mobile?).to eq mobile
          expect(p.canonical).to eq canonical
        end
      end
    end

    context "test data" do
      before(:each) do
        @numbers = File.readlines(Rails.root + "spec/files/phones.txt").reject{ |l| l.blank? }
        @unparsed = @numbers.reject { |number| Phone.new(number).parsed? }
      end

      it "over 93% parsable" do
        expect(@numbers.size).to be > 3600
        expect(100.0 * @unparsed.size / @numbers.size).to be < 7.0
      end
    end
  end
end
