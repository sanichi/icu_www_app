require 'rails_helper'

describe PaymentsController do
  context "no cart exists" do
    it "cart page creates one" do
      expect(Cart.count).to eq 0
      get "cart"
      expect(response).to_not be_redirect
      expect(Cart.count).to eq 1
      cart = Cart.last
      expect(cart.unpaid?).to be true
      expect(session[:cart_id]).to eq cart.id
    end

    it "card page gets a redirect and doesn't set the session" do
      expect(Cart.count).to eq 0
      get "card"
      expect(response).to redirect_to shop_path
      expect(Cart.count).to eq 0
      expect(session[:cart_id]).to be_nil
    end

    it "confirm page gets a redirect and doesn't set the session" do
      expect(Cart.count).to eq 0
      get "confirm"
      expect(response).to redirect_to shop_path
      expect(Cart.count).to eq 0
      expect(session[:cart_id]).to be_nil
    end
  end

  context "a cart exists but not in the session" do
    before(:each) do
      @cart_id = create(:cart).id
    end

    it "cart page creates a new cart" do
      expect(Cart.count).to eq 1
      get "cart"
      expect(response).to_not be_redirect
      expect(Cart.count).to eq 2
      expect(session[:cart_id]).to eq @cart_id + 1
    end

    it "card page gets a redirect and doesn't set the session" do
      expect(Cart.count).to eq 1
      get "card"
      expect(response).to redirect_to shop_path
      expect(Cart.count).to eq 1
      expect(session[:cart_id]).to be_nil
    end

    it "confirm page gets a redirect and doesn't set the session" do
      expect(Cart.count).to eq 1
      get "confirm"
      expect(response).to redirect_to shop_path
      expect(Cart.count).to eq 1
      expect(session[:cart_id]).to be_nil
    end
  end

  context "the current cart is unpaid and empty" do
    before(:each) do
      @cart_id = create(:cart).id
      session[:cart_id] = @cart_id
    end

    it "cart page shows the cart" do
      expect(Cart.count).to eq 1
      get "cart"
      expect(response).to_not be_redirect
      expect(Cart.count).to eq 1
      expect(session[:cart_id]).to eq @cart_id
    end

    it "card page gets a redirect and doesn't alter the session" do
      expect(Cart.count).to eq 1
      get "card"
      expect(response).to redirect_to shop_path
      expect(Cart.count).to eq 1
      expect(session[:cart_id]).to eq @cart_id
    end

    it "confirm page gets a redirect and doesn't alter the session" do
      expect(Cart.count).to eq 1
      get "confirm"
      expect(response).to redirect_to shop_path
      expect(Cart.count).to eq 1
      expect(session[:cart_id]).to eq @cart_id
    end
  end

  context "a paid cart" do
    before(:each) do
      fee = create(:subscription_fee)
      cart = create(:cart,
        status: "paid",
        total: fee.amount,
        original_total: fee.amount,
        payment_method: "stripe",
        payment_ref: "ch_3QMTIr9JTJmjex",
        confirmation_email: "mark@markorr.net",
        payment_name: "DR MARK J L ORR",
        payment_completed: Time.now
      )
      item = create(:paid_subscription_item, fee: fee, cart: cart)
      @cart_id = cart.id
    end

    context "is the current cart" do
      before(:each) do
        session[:cart_id] = @cart_id
      end

      it "cart page clears the session and creates a new empty cart" do
        expect(Cart.count).to eq 1
        get "cart"
        expect(response).to_not be_redirect
        expect(Cart.count).to eq 2
        cart = Cart.last
        expect(cart.unpaid?).to be true
        expect(cart.items.empty?).to be true
        expect(session[:cart_id]).to eq cart.id
      end

      it "card page clears the current cart and gets a redirect" do
        expect(Cart.count).to eq 1
        get "card"
        expect(response).to redirect_to shop_path
        expect(Cart.count).to eq 1
        expect(session[:cart_id]).to eq nil
      end

      it "confirm page gets a redirect but doesn't alter the current cart" do
        expect(Cart.count).to eq 1
        get "confirm"
        expect(response).to redirect_to shop_path
        expect(Cart.count).to eq 1
        expect(session[:cart_id]).to eq @cart_id
      end
    end

    context "is the last completed" do
      before(:each) do
        session[:completed_carts] = [@cart_id]
      end

      it "cart page creates a new empty unpaid cart" do
        expect(Cart.count).to eq 1
        get "cart"
        expect(response).to_not be_redirect
        expect(Cart.count).to eq 2
        cart = Cart.last
        expect(cart.unpaid?).to be true
        expect(cart.items.empty?).to be true
        expect(session[:cart_id]).to eq cart.id
      end

      it "card page gets a redirect and leaves the current cart alone" do
        expect(Cart.count).to eq 1
        get "card"
        expect(response).to redirect_to shop_path
        expect(Cart.count).to eq 1
        expect(session[:cart_id]).to eq nil
      end

      it "confirm page doesn't get a redirect and doesn't alter the current cart" do
        expect(Cart.count).to eq 1
        get "confirm"
        expect(response).to_not be_redirect
        expect(Cart.count).to eq 1
        expect(session[:cart_id]).to eq nil
      end
    end
  end
end
