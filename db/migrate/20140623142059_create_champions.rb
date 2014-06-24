class CreateChampions < ActiveRecord::Migration
  def change
    create_table :champions do |t|
      t.string   :category, limit: 20
      t.string   :notes, limit: 140
      t.string   :winners
      t.integer  :year, limit: 2

      t.timestamps
    end

    add_index :champions, :category
    add_index :champions, :winners
    add_index :champions, :year
  end
end
