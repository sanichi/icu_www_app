class CreateCartItems < ActiveRecord::Migration
  def change
    create_table :cart_items do |t|
      t.string   :cartable_type, limit: 30
      t.integer  :cartable_id, :cart_id
      t.string   :description
      t.string   :status, limit: 20, default: "unpaid"
      t.decimal  :cost, precision: 6, scale: 2
      t.datetime :created_at
    end

    add_index :cart_items, [:cartable_type, :cartable_id]
    add_index :cart_items, :cart_id
  end
end
