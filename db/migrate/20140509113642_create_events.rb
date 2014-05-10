class CreateEvents < ActiveRecord::Migration
  def change
    create_table   :events do |t|
      t.boolean    :active
      t.string     :category, limit: 25
      t.string     :contact, limit: 50
      t.string     :email, limit: 50
      t.attachment :flyer
      t.decimal    :lat, precision: 10, scale: 7
      t.string     :location, limit: 100
      t.decimal    :long, precision: 10, scale: 7
      t.string     :name, limit: 75
      t.string     :note, limit: 512
      t.string     :phone, limit: 25
      t.decimal    :prize_fund, precision: 8, scale: 2
      t.string     :source, limit: 8, default: "www2"
      t.date       :start_date, :end_date
      t.string     :url, limit: 75
      t.integer    :user_id

      t.timestamps
    end

    add_index :events, :active
    add_index :events, :end_date
    add_index :events, :location
    add_index :events, :name
    add_index :events, :start_date
    add_index :events, :user_id
  end
end
