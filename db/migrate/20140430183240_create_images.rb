class CreateImages < ActiveRecord::Migration
  def change
    create_table   :images do |t|
      t.attachment :data
      t.string     :caption, :dimensions
      t.string     :credit, limit: 100
      t.string     :source, limit: 8, default: "www2"
      t.integer    :year, limit: 2
      t.integer    :user_id

      t.timestamps
    end

    add_index :images, :caption
    add_index :images, :year
    add_index :images, :credit
    add_index :images, :user_id
  end
end
