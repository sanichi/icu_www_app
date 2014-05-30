class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string   :annotator, limit: 50
      t.string   :black, limit: 50
      t.integer  :black_elo, limit: 2
      t.string   :date, limit: 10
      t.string   :eco, limit: 3
      t.string   :event, limit: 50
      t.string   :fen, limit: 100
      t.text     :moves
      t.integer  :pgn_id
      t.integer  :ply, limit: 2
      t.string   :result, limit: 3
      t.string   :round, limit: 7
      t.string   :signature, limit: 32
      t.string   :site, limit: 50
      t.string   :white, limit: 50
      t.integer  :white_elo, limit: 2

      t.timestamps
    end

    add_index :games, :black
    add_index :games, :date
    add_index :games, :eco
    add_index :games, :event
    add_index :games, :result
    add_index :games, :signature
    add_index :games, :white
  end
end
