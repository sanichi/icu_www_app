class CreateEntries < ActiveRecord::Migration
  def change
    create_table :entries do |t|
      t.integer  :player_id, :entry_fee_id
      t.string   :description
      t.date     :event_start, :event_end
      t.decimal  :cost, precision: 6, scale: 2
      t.string   :payment_method, limit: 20

      t.datetime :created_at
    end

    add_index :entries, :player_id
    add_index :entries, :entry_fee_id
    add_index :entries, :payment_method
  end
end
