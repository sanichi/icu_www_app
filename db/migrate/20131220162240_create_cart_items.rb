class CreateCartItems < ActiveRecord::Migration
  def change
    create_table :cart_items do |t|
      t.string   :cartable_type, limit: 30
      t.integer  :cartable_id, :cart_id
      t.datetime :created_at
    end

    add_index :cart_items, [:cartable_type, :cartable_id]
    add_index :cart_items, :cart_id
  end
end
