class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.integer  :player_id, :subscription_fee_id
      t.string   :season_desc, limit: 7
      t.boolean  :active, default: false
      t.datetime :created_at
    end

    add_index :subscriptions, :player_id
    add_index :subscriptions, :subscription_fee_id
    add_index :subscriptions, :season_desc
    add_index :subscriptions, :active
  end
end
