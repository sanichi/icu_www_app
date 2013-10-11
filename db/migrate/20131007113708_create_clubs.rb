class CreateClubs < ActiveRecord::Migration
  def change
    create_table :clubs do |t|
      t.string   :name, :district, :city, :contact, :email, :phone, limit: 50
      t.string   :web, :address, limit: 100
      t.string   :meet
      t.string   :county, limit: 20
      t.decimal  :lat, :long, precision: 10, scale: 7
      t.boolean  :active

      t.timestamps
    end
  end
end
