class CreateClubs < ActiveRecord::Migration
  def change
    create_table :clubs do |t|
      t.string   :province, limit: 10
      t.string   :county, limit: 20
      t.string   :name, :city, :district, :contact, :email, :phone, limit: 50
      t.string   :address, :web, limit: 100
      t.string   :meetings
      t.boolean  :active
      t.decimal  :latitude, :longitude, precision: 10, scale: 7

      t.timestamps
    end
  end
end
