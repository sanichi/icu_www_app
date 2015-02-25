class AddPaymentAccountToCarts < ActiveRecord::Migration
  def up
    add_column :carts, :payment_account, :string, limit: 32
    Cart.where(payment_method: "stripe").each do |cart|
      cart.update_column(:payment_account, Cart.current_payment_account)
    end
  end

  def down
    remove_column :carts, :payment_account
  end
end
