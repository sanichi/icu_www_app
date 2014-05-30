class CreatePgns < ActiveRecord::Migration
  def change
    create_table :pgns do |t|
      t.string   :comment
      t.string   :content_type
      t.integer  :duplicates, default: 0
      t.string   :file_name
      t.integer  :file_size, default: 0
      t.integer  :game_count, default: 0
      t.integer  :imports, default: 0
      t.integer  :lines, default: 0
      t.string   :problem
      t.integer  :user_id

      t.timestamps
    end
  end
end
