class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string   :first_name, :last_name, limit: 50
      t.string   :status, :source, limit: 25
      t.integer  :player_id
      t.string   :gender, limit: 1
      t.date     :dob, :joined

      t.timestamps
    end
    
    add_index :players, [:first_name, :last_name]
    add_index :players, :first_name
    add_index :players, :last_name
  end
end
