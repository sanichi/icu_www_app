class CreateCarts < ActiveRecord::Migration
  def change
    create_table :carts do |t|
      t.string   :status, limit: 20, default: "unpaid"
      t.decimal  :total, :original_total, precision: 8, scale: 2
      t.string   :payment_method, limit: 20
      t.string   :payment_ref, :confirmation_email, limit: 50
      t.string   :payment_name, limit: 100
      t.integer  :user_id
      t.datetime :payment_completed

      t.timestamps
    end
  end
end
