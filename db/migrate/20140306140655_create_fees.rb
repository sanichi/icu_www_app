class CreateFees < ActiveRecord::Migration
  def change
    create_table :fees do |t|
      t.string   :type, limit: 40
      t.string   :name, limit: 100
      t.decimal  :amount, :discounted_amount, precision: 9, scale: 2
      t.string   :years, limit: 7
      t.integer  :year, :days, limit: 2
      t.date     :start_date, :end_date, :sale_start, :sale_end, :age_ref_date, :discount_deadline
      t.integer  :min_age, :max_age, limit: 1
      t.integer  :min_rating, :max_rating, limit: 2
      t.string   :url
      t.boolean  :active, default: false
      t.boolean  :player_required, default: true

      t.timestamps
    end
  end
end
