class CreateEntryFees < ActiveRecord::Migration
  def change
    create_table :entry_fees do |t|
      t.string   :event_name, limit: 100
      t.string   :year_or_season, limit: 7
      t.decimal  :amount, :discounted_amount, precision: 6, scale: 2
      t.date     :sale_start, :sale_end, :discount_deadline
      t.date     :event_start, :event_end
      t.string   :event_website
      t.integer  :player_id

      t.timestamps
    end
  end
end
