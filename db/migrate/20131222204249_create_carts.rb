class CreateCarts < ActiveRecord::Migration
  def change
    create_table :carts do |t|
      t.datetime :payment_completed
      t.string   :status, limit: 20, default: "unpaid"

      t.timestamps
    end
  end
end
