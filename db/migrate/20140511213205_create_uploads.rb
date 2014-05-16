class CreateUploads < ActiveRecord::Migration
  def change
    create_table :uploads do |t|
      t.string     :access, limit: 20
      t.attachment :data
      t.string     :description, limit: 150
      t.string     :www1_path, limit: 128
      t.integer    :user_id
      t.integer    :year, limit: 2

      t.timestamps
    end

    add_index :uploads, :access
    add_index :uploads, :description
    add_index :uploads, :user_id
    add_index :uploads, :www1_path
    add_index :uploads, :year
  end
end
