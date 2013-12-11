class CreateSubscriptionFees < ActiveRecord::Migration
  def change
    create_table :subscription_fees do |t|
      t.string   :category, limit: 20
      t.decimal  :amount, precision: 6, scale: 2
      t.string   :season_desc, limit: 7
      t.date     :sale_start, :sale_end, :age_ref_date

      t.timestamps
    end
  end
end
