class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.string   :access, limit: 20
      t.boolean  :active
      t.string   :author, limit: 100
      t.string   :category, limit: 20
      t.text     :text
      t.string   :title, limit: 100
      t.boolean  :markdown, default: true
      t.integer  :user_id
      t.integer  :year, limit: 2

      t.timestamps
    end

    add_index :articles, :access
    add_index :articles, :active
    add_index :articles, :author
    add_index :articles, :category
    add_index :articles, :title
    add_index :articles, :user_id
    add_index :articles, :year
  end
end
