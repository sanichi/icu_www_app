class CreateEpisodes < ActiveRecord::Migration
  def change
    create_table :episodes do |t|
      t.integer  :article_id
      t.integer  :series_id
      t.integer  :number, limit: 2

      t.timestamps
    end

    add_index :episodes, :article_id
    add_index :episodes, :series_id
  end
end
