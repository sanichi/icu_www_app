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
      payment_error = PaymentError.factory(card_error, name, email)
      expect(payment_error.payment_name).to eq name
      expect(payment_error.confirmation_email).to eq email
      expect(payment_error.message).to eq card
      expect(payment_error.details).to match /:type=>\"#{type}\"/
      expect(payment_error.details).to_not match /:message=>/
    end

    it "other error" do
      payment_error = PaymentError.factory(other_error, name, email, message: override)
      expect(payment_error.payment_name).to eq name
      expect(payment_error.confirmation_email).to eq email
      expect(payment_error.message).to eq override
      expect(payment_error.details).to match /:type=>\"#{type}\"/
      expect(payment_error.details).to match /:message=>\"#{other}\"/
    end

    it "unexpected error" do
      payment_error = PaymentError.factory(unexpected_error, name, email, message: override)
      expect(payment_error.payment_name).to eq name
      expect(payment_error.confirmation_email).to eq email
      expect(payment_error.message).to eq override
      expect(payment_error.details).to eq unexpected
    end

    it "weird error" do
      payment_error = PaymentError.factory(weird_error, name, email, message: override)
      expect(payment_error.payment_name).to eq name
      expect(payment_error.confirmation_email).to eq email
      expect(payment_error.message).to eq override
      expect(payment_error.details).to be_nil
    end
  end
end
