require 'rails_helper'

describe CashPayment do
  let(:blank) { CashPayment.new }

  # Adapted from https://github.com/rails/rails/blob/master/activemodel/lib/active_model/lint.rb.
  context "lint" do
    let(:model_name) { CashPayment.model_name }

    it "instance methods" do
      expect(blank.to_key).to be_nil
      expect(blank.to_param).to be_nil
      expect(blank.to_partial_path).to eq "cash_payments/cash_payment"
    end

    it "model name" do
      expect(model_name.to_str).to eq "CashPayment"
      expect(model_name.human.to_str).to eq "Cash payment"
      expect(model_name.singular.to_str).to eq "cash_payment"
      expect(model_name.plural.to_str).to eq "cash_payments"
    end
  end

  context "validation" do
    it "blank" do
      expect(blank).to_not be_valid
      errors = blank.errors
      [:first_name, :last_name, :payment_method, :amount].each do |atr|
       expect(errors[atr]).to be_present
      end
    end

    it "factory" do
      expect(create(:cash_payment)).to be_valid
      expect(create(:cash_payment, email: nil)).to be_valid
      expect(create(:cash_payment, payment_method: "stripe")).to_not be_valid
    end
  end

  context "canonicalisation" do
    let(:untidy) { create(:cash_payment, first_name: " SARAH- JANE  g", last_name: " lowRy - O rEillY  ", email: " ", amount: " 12.3456789 ") }

    it "name" do
      expect(untidy.first_name).to eq "Sarah-Jane G."
      expect(untidy.last_name).to eq "Lowry-O'Reilly"
    end

    it "email" do
      expect(untidy.email).to be_nil
    end

    it "amount" do
      expect(untidy.amount).to be_a BigDecimal
      expect(untidy.amount).to eq 12.35
    end

    it "valid" do
      expect(untidy).to be_valid
    end
  end
end
