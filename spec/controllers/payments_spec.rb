require 'spec_helper'

describe PaimentsController do
  context "no cart exists" do
    it "cart page creates one" do
      expect(Kart.count).to eq 0
      get "xcart"
      expect(response).to_not be_redirect
      expect(Kart.count).to eq 1
      kart = Kart.last
      expect(kart.unpaid?).to be_true
      expect(session[:kart_id]).to eq kart.id
    end

    it "card page gets a redirect and doesn't set the session" do
      expect(Kart.count).to eq 0
      get "xcard"
      expect(response).to redirect_to xshop_path
      expect(Kart.count).to eq 0
      expect(session[:kart_id]).to be_nil
    end

    it "confirm page gets a redirect and doesn't set the session" do
      expect(Kart.count).to eq 0
      get "xconfirm"
      expect(response).to redirect_to xshop_path
      expect(Kart.count).to eq 0
      expect(session[:kart_id]).to be_nil
    end
  end

  context "a cart exists but not in the session" do
    before(:each) do
      @kart_id = create(:kart).id
    end

    it "cart page creates a new cart" do
      expect(Kart.count).to eq 1
      get "xcart"
      expect(response).to_not be_redirect
      expect(Kart.count).to eq 2
      expect(session[:kart_id]).to eq @kart_id + 1
    end

    it "card page gets a redirect and doesn't set the session" do
      expect(Kart.count).to eq 1
      get "xcard"
      expect(response).to redirect_to xshop_path
      expect(Kart.count).to eq 1
      expect(session[:kart_id]).to be_nil
    end

    it "confirm page gets a redirect and doesn't set the session" do
      expect(Kart.count).to eq 1
      get "xconfirm"
      expect(response).to redirect_to xshop_path
      expect(Kart.count).to eq 1
      expect(session[:kart_id]).to be_nil
    end
  end

  context "the current cart is unpaid and empty" do
    before(:each) do
      @kart_id = create(:kart).id
      session[:kart_id] = @kart_id
    end

    it "cart page shows the cart" do
      expect(Kart.count).to eq 1
      get "xcart"
      expect(response).to_not be_redirect
      expect(Kart.count).to eq 1
      expect(session[:kart_id]).to eq @kart_id
    end

    it "card page gets a redirect and doesn't alter the session" do
      expect(Kart.count).to eq 1
      get "xcard"
      expect(response).to redirect_to xshop_path
      expect(Kart.count).to eq 1
      expect(session[:kart_id]).to eq @kart_id
    end

    it "confirm page gets a redirect and doesn't alter the session" do
      expect(Kart.count).to eq 1
      get "xconfirm"
      expect(response).to redirect_to xshop_path
      expect(Kart.count).to eq 1
      expect(session[:kart_id]).to eq @kart_id
    end
  end

  context "a paid cart" do
    before(:each) do
      fee = create(:subscripsion_fee)
      kart = create(:kart,
        status: "paid",
        total: fee.amount,
        original_total: fee.amount,
        payment_method: "stripe",
        payment_ref: "ch_3QMTIr9JTJmjex",
        confirmation_email: "mark@markorr.net",
        payment_name: "DR MARK J L ORR",
        payment_completed: Time.now
      )
      item = create(:paid_subscripsion_item, fee: fee, kart: kart)
      @kart_id = kart.id
    end

    context "is the current cart" do
      before(:each) do
        session[:kart_id] = @kart_id
      end

      it "cart page clears the session and creates a new empty cart" do
        expect(Kart.count).to eq 1
        get "xcart"
        expect(response).to_not be_redirect
        expect(Kart.count).to eq 2
        kart = Kart.last
        expect(kart.unpaid?).to be_true
        expect(kart.items.empty?).to be_true
        expect(session[:kart_id]).to eq kart.id
      end

      it "card page clears the current cart and gets a redirect" do
        expect(Kart.count).to eq 1
        get "xcard"
        expect(response).to redirect_to xshop_path
        expect(Kart.count).to eq 1
        expect(session[:kart_id]).to eq nil
      end

      it "confirm page gets a redirect but doesn't alter the current cart" do
        expect(Kart.count).to eq 1
        get "xconfirm"
        expect(response).to redirect_to xshop_path
        expect(Kart.count).to eq 1
        expect(session[:kart_id]).to eq @kart_id
      end
    end

    context "is the last completed" do
      before(:each) do
        session[:completed_karts] = [@kart_id]
      end

      it "cart page creates a new empty unpaid cart" do
        expect(Kart.count).to eq 1
        get "xcart"
        expect(response).to_not be_redirect
        expect(Kart.count).to eq 2
        kart = Kart.last
        expect(kart.unpaid?).to be_true
        expect(kart.items.empty?).to be_true
        expect(session[:kart_id]).to eq kart.id
      end

      it "card page gets a redirect and leaves the current cart alone" do
        expect(Kart.count).to eq 1
        get "xcard"
        expect(response).to redirect_to xshop_path
        expect(Kart.count).to eq 1
        expect(session[:kart_id]).to eq nil
      end

      it "confirm page doesn't get a redirect and doesn't alter the current cart" do
        expect(Kart.count).to eq 1
        get "xconfirm"
        expect(response).to_not be_redirect
        expect(Kart.count).to eq 1
        expect(session[:kart_id]).to eq nil
      end
    end
  end
end
