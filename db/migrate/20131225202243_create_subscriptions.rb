class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.integer  :player_id, :subscription_fee_id
      t.string   :season_desc, limit: 7
      t.string   :source, limit: 8, default: "www2"
      t.string   :category, :payment_method, limit: 20
      t.decimal  :cost, precision: 6, scale: 2

      t.datetime :created_at
    end

    add_index :subscriptions, :player_id
    add_index :subscriptions, :subscription_fee_id
    add_index :subscriptions, :season_desc
    add_index :subscriptions, :payment_method
  end
end
