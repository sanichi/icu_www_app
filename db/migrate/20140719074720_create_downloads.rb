class CreateDownloads < ActiveRecord::Migration
  def change
    create_table :downloads do |t|
      t.string     :access, limit: 20
      t.attachment :data
      t.string     :description, limit: 150
      t.string     :www1_path, limit: 128
      t.integer    :user_id
      t.integer    :year, limit: 2

      t.timestamps
    end

    add_index :downloads, :access
    add_index :downloads, :description
    add_index :downloads, :user_id
    add_index :downloads, :www1_path
    add_index :downloads, :year
  end
end
