class CreateNews < ActiveRecord::Migration
  def change
    create_table :news do |t|
      t.boolean  :active
      t.date     :date
      t.string   :headline, limit: 100
      t.text     :summary
      t.integer  :user_id

      t.timestamps
    end

    add_index :news, :active
    add_index :news, :date
    add_index :news, :headline
    add_index :news, :user_id
  end
end
