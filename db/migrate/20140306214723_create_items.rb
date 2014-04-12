class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string   :type, limit: 40
      t.integer  :player_id, :fee_id, :cart_id
      t.string   :description, :player_data
      t.date     :start_date, :end_date
      t.decimal  :cost, precision: 6, scale: 2
      t.string   :status, limit: 20, default: "unpaid"
      t.string   :source, limit: 8, default: "www2"
      t.string   :payment_method, limit: 20
      t.string   :notes, limit: 1000, default: [].to_yaml

      t.timestamps
    end
  end
end
