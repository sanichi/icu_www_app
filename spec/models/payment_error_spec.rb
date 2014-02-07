require 'spec_helper'

describe PaymentError do
  context "factory" do
    let(:error)            { Struct.new(:message, :json_body) }
    let(:name)             { "Mark" }
    let(:email)            { "mark@markorr.net" }
    let(:type)             { "error_type" }
    let(:card)             { "Card expiry" }
    let(:card_error)       { error.new(card, { error: { message: card, type: type } }) }
    let(:other)            { "Other error" }
    let(:override)         { "Override message" }
    let(:other_error)      { error.new(other, { error: { message: other, type: type } }) }
    let(:unexpected)       { "Unexpected" }
    let(:unexpected_error) { error.new(unexpected, { error: unexpected }) }
    let(:weird)            { "Weird" }
    let(:weird_error)      { error.new(weird) }

    it "card error" do
      params = PaymentError.params(card_error, name, email)
      expect(params[:payment_name]).to eq name
      expect(params[:confirmation_email]).to eq email
      expect(params[:message]).to eq card
      expect(params[:details]).to match /:type=>\"#{type}\"/
      expect(params[:details]).to_not match /:message=>/
    end

    it "other error" do
      params = PaymentError.params(other_error, name, email, message: override)
      expect(params[:payment_name]).to eq name
      expect(params[:confirmation_email]).to eq email
      expect(params[:message]).to eq override
      expect(params[:details]).to match /:type=>\"#{type}\"/
      expect(params[:details]).to match /:message=>\"#{other}\"/
    end

    it "unexpected error" do
      params = PaymentError.params(unexpected_error, name, email, message: override)
      expect(params[:payment_name]).to eq name
      expect(params[:confirmation_email]).to eq email
      expect(params[:message]).to eq override
      expect(params[:details]).to eq unexpected
    end

    it "weird error" do
      params = PaymentError.params(weird_error, name, email, message: override)
      expect(params[:payment_name]).to eq name
      expect(params[:confirmation_email]).to eq email
      expect(params[:message]).to eq override
      expect(params[:details]).to be_nil
    end
  end
end
