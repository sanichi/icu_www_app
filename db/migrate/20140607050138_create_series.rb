class CreateSeries < ActiveRecord::Migration
  def change
    create_table :series do |t|
      t.string   :title, limit: 100

      t.timestamps
    end

    add_index :series, :title
  end
end
