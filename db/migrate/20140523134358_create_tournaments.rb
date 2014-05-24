class CreateTournaments < ActiveRecord::Migration
  def change
    create_table :tournaments do |t|
      t.boolean  :active
      t.string   :category, limit: 20
      t.string   :city, limit: 50
      t.text     :details
      t.string   :format, limit: 20
      t.string   :name, limit: 80
      t.integer  :year, limit: 2

      t.timestamps
    end

    add_index :tournaments, :active
    add_index :tournaments, :category
    add_index :tournaments, :city
    add_index :tournaments, :format
    add_index :tournaments, :name
    add_index :tournaments, :year
  end
end
