require 'spec_helper'

describe EntryFee do
  context "implicitly set attributes" do
    let(:fee) { create(:entry_fee, event_name: "Bunratty Masters", event_start: "2014-02-05", event_end: "2014-02-07") }

    it "sale start and end dates" do
      expect(fee.sale_start.to_s).to eq "2013-11-05"
      expect(fee.sale_end.to_s).to eq "2014-02-04"
    end

    it "#year_or_season" do
      expect(fee.year_or_season).to eq "2014"
    end

    it "#description" do
      expect(fee.description).to eq "Bunratty Masters 2014"
    end
  end

  context "more implicitly set attributes" do
    let(:fee) { create(:entry_fee, event_name: "Ulster New Year Special", amount: "50", event_start: "2013-12-27", event_end: "2014-01-02", discounted_amount: "40", discount_deadline: "2013-12-01") }

    it "sale start and end dates" do
      expect(fee.sale_start.to_s).to eq "2013-09-27"
      expect(fee.sale_end.to_s).to eq "2013-12-26"
    end

    it "#year_or_season" do
      expect(fee.year_or_season).to eq "2013-14"
    end

    it "#description" do
      expect(fee.description).to eq "Ulster New Year Special 2013-14"
    end
  end

  context "errors" do
    let(:params) { attributes_for(:entry_fee, discounted_amount: 40, discount_deadline: "2014-02-01", event_start: "2014-02-05", event_end: "2014-02-09", sale_start: "2013-11-01", sale_end: "2014-02-03") }

    it "ok" do
      expect{EntryFee.create!(params)}.to_not raise_error
    end

    it "bad discount" do
      expect{EntryFee.create!(params.merge(discounted_amount: 100))}.to raise_error(/discount/)
    end

    it "bad event start" do
      expect{EntryFee.create!(params.merge(event_start: "2014-02-10"))}.to raise_error(/start/)
    end

    it "bad event end" do
      expect{EntryFee.create!(params.merge(event_end: "2016-02-10"))}.to raise_error(/end/)
    end

    it "bad sale start" do
      expect{EntryFee.create!(params.merge(sale_start: "2014-02-10"))}.to raise_error(/start/)
    end

    it "bad sale end" do
      expect{EntryFee.create!(params.merge(sale_end: "2014-02-07"))}.to raise_error(/before/)
      expect{EntryFee.create!(params.merge(sale_end: "2013-10-01"))}.to raise_error(/start/)
    end
  end

  context "contact errors" do
    let(:params) { attributes_for(:entry_fee) }

    it "invalid ID" do
      expect{EntryFee.create!(params.merge(player_id: "1"))}.to raise_error(/invalid.*ID/i)
    end

    it "player without email" do
      player = create(:player, email: nil)
      expect{EntryFee.create!(params.merge(player_id: player.id))}.to raise_error(/email/i)
    end

    it "player without any logins" do
      player = create(:player, email: "tournaments@icu.ie")
      expect{EntryFee.create!(params.merge(player_id: player.id))}.to raise_error(/login/i)
    end

    it "player who is not a current member" do
      player = create(:player, email: "tournaments@icu.ie")
      user = create(:user, player: player, expires_on: Date.today.last_year.at_end_of_year)
      expect{EntryFee.create!(params.merge(player_id: player.id))}.to raise_error(/current member/i)
    end

    it "player who is a current member" do
      player = create(:player, email: "tournaments@icu.ie")
      user = create(:user, player: player, expires_on: Date.today.next_year.at_beginning_of_year)
      expect{EntryFee.create!(params.merge(player_id: player.id))}.to_not raise_error
    end
  end

  context "website errors" do
    let(:params) { attributes_for(:entry_fee) }

    it "invalid URL" do
      expect{EntryFee.create!(params.merge(event_website: "x"))}.to raise_error(/invalid/i)
    end

    it "bad URL" do
      expect{EntryFee.create!(params.merge(event_website: "http://www.icu.ie/no_such_page.html"))}.to raise_error(/bad response/i)
    end

    it "URL OK" do
      expect{EntryFee.create!(params.merge(event_website: "http://www.icu.ie/"))}.to_not raise_error
    end

    it "URL OK even without path" do
      expect{EntryFee.create!(params.merge(event_website: "http://www.icu.ie"))}.to_not raise_error
    end
  end

  context "rollover" do
    let(:fee) { create(:entry_fee, event_name: "Kilkenny Challengers", amount: 45, discounted_amount: 35, discount_deadline: "2013-09-15", event_start: "2013-09-22", event_end: "2013-09-24", sale_start: "2013-07-01", sale_end: "2013-09-20") }

    it "#rolloverable?" do
      expect(fee.rolloverable?).to be_true
      rof = fee.rollover
      expect(fee.rolloverable?).to be_false
    end

    it "#rollover" do
      rof = fee.rollover
      expect(rof.event_name).to eq fee.event_name
      expect(rof.year_or_season).to eq (fee.year_or_season.to_i + 1).to_s
      expect(rof.amount).to eq fee.amount
      expect(rof.discounted_amount).to eq fee.discounted_amount
      expect(rof.event_start).to eq fee.event_start.years_since(1)
      expect(rof.event_end).to eq fee.event_end.years_since(1)
      expect(rof.sale_start).to eq fee.sale_start.years_since(1)
      expect(rof.sale_end).to eq fee.sale_end.years_since(1)
    end
  end
end
