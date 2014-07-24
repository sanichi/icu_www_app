require 'rails_helper'

describe Fee::Entry do
  context "implicitly set attributes" do
    let(:fee) { create(:entry_fee, sale_start: nil, sale_end: nil) }

    it "sale start and end dates" do
      expect(fee.sale_start).to eq fee.start_date.months_ago(3)
      expect(fee.sale_end).to eq fee.start_date.days_ago(1)
    end

    it "#year" do
      expect(fee.year).to eq fee.start_date.year
    end

    it "#description" do
      expect(fee.description).to eq "#{fee.name} #{fee.year}"
    end
  end

  context "more implicitly set attributes" do
    let(:late_next_year) { Date.today.next_year.end_of_year.days_ago(2) }
    let(:fee) { create(:entry_fee, name: "Ulster End of Year Special", amount: "50", start_date: late_next_year, end_date: late_next_year.days_since(10), sale_start: nil, sale_end: nil, discounted_amount: "40", discount_deadline: late_next_year.days_ago(10)) }

    it "sale start and end dates" do
      expect(fee.sale_start).to eq late_next_year.months_ago(3)
      expect(fee.sale_end).to eq late_next_year.days_ago(1)
    end

    it "#year_or_season" do
      expect(fee.years).to eq Season.new(late_next_year).to_s
    end

    it "#description" do
      expect(fee.description).to eq "#{fee.name} #{Season.new(late_next_year).to_s}"
    end
  end

  context "errors" do
    let(:params) { attributes_for(:entry_fee, discounted_amount: 40, discount_deadline: Date.today.days_since(7)) }

    it "ok" do
      expect{Fee::Entry.create!(params)}.to_not raise_error
    end

    it "bad discount" do
      expect{Fee::Entry.create!(params.merge(discounted_amount: 100))}.to raise_error(/discount/)
    end

    it "bad event start" do
      expect{Fee::Entry.create!(params.merge(start_date: params[:end_date].days_since(1)))}.to raise_error(/start/)
    end

    it "bad event end" do
      expect{Fee::Entry.create!(params.merge(end_date: params[:start_date].days_ago(1)))}.to raise_error(/end/)
    end

    it "bad sale start" do
      expect{Fee::Entry.create!(params.merge(sale_start: params[:start_date].days_since(1)))}.to raise_error(/start/)
    end

    it "bad sale end" do
      expect{Fee::Entry.create!(params.merge(sale_end: params[:start_date].days_since(1)))}.to raise_error(/before/)
      expect{Fee::Entry.create!(params.merge(sale_end: params[:sale_start].days_ago(4)))}.to raise_error(/start/)
    end
  end

  context "url errors" do
    let(:params) { attributes_for(:entry_fee) }

    it "invalid URL" do
      expect{Fee::Entry.create!(params.merge(url: "ftp://icu.ie"))}.to raise_error(/invalid/i)
    end

    it "bad URL" do
      pending "resolution of problem noted in Fee#valid_url"
      expect{Fee::Entry.create!(params.merge(url: "http://www.icu.ie/no_such_page.html"))}.to raise_error(/bad response/i)
    end

    it "URL OK" do
      expect{Fee::Entry.create!(params.merge(url: "http://www.icu.ie/"))}.to_not raise_error
    end

    it "URL OK even without path" do
      expect{Fee::Entry.create!(params.merge(url: "http://www.icu.ie"))}.to_not raise_error
    end
  end
end
