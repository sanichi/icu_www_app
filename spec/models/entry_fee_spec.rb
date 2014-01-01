require 'spec_helper'

describe EntryFee do
  context "implicitly set attributes" do
    let(:fee) { create(:entry_fee, sale_start: nil, sale_end: nil) }

    it "sale start and end dates" do
      expect(fee.sale_start).to eq fee.event_start.months_ago(3)
      expect(fee.sale_end).to eq fee.event_start.days_ago(1)
    end

    it "#year_or_season" do
      expect(fee.year_or_season).to eq fee.event_start.year.to_s
    end

    it "#description" do
      expect(fee.description).to eq "#{fee.event_name} #{fee.event_start.year}"
    end
  end

  context "more implicitly set attributes" do
    let(:late_next_year) { Date.today.next_year.end_of_year.days_ago(2) }
    let(:fee) { create(:entry_fee, event_name: "Ulster End of Year Special", amount: "50", event_start: late_next_year, event_end: late_next_year.days_since(10), sale_start: nil, sale_end: nil, discounted_amount: "40", discount_deadline: late_next_year.days_ago(10)) }

    it "sale start and end dates" do
      expect(fee.sale_start).to eq late_next_year.months_ago(3)
      expect(fee.sale_end).to eq late_next_year.days_ago(1)
    end

    it "#year_or_season" do
      expect(fee.year_or_season).to eq Season.new(late_next_year).desc
    end

    it "#description" do
      expect(fee.description).to eq "#{fee.event_name} #{Season.new(late_next_year).desc}"
    end
  end

  context "errors" do
    let(:params) { attributes_for(:entry_fee, discounted_amount: 40, discount_deadline: Date.today.days_since(7)) }

    it "ok" do
      expect{EntryFee.create!(params)}.to_not raise_error
    end

    it "bad discount" do
      expect{EntryFee.create!(params.merge(discounted_amount: 100))}.to raise_error(/discount/)
    end

    it "bad event start" do
      expect{EntryFee.create!(params.merge(event_start: params[:event_end].days_since(1)))}.to raise_error(/start/)
    end

    it "bad event end" do
      expect{EntryFee.create!(params.merge(event_end: params[:event_start].days_ago(1)))}.to raise_error(/end/)
    end

    it "bad sale start" do
      expect{EntryFee.create!(params.merge(sale_start: params[:event_start].days_since(1)))}.to raise_error(/start/)
    end

    it "bad sale end" do
      expect{EntryFee.create!(params.merge(sale_end: params[:event_start].days_since(1)))}.to raise_error(/before/)
      expect{EntryFee.create!(params.merge(sale_end: params[:sale_start].days_ago(4)))}.to raise_error(/start/)
    end
  end

  context "contact errors" do
    let(:params) { attributes_for(:entry_fee) }

    it "invalid ID" do
      expect{EntryFee.create!(params.merge(player_id: "1"))}.to raise_error(/invalid/i)
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
end
