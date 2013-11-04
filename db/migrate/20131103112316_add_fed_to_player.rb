class AddFedToPlayer < ActiveRecord::Migration
  def change
    add_column :players, :fed, :string, limit: 3
  end
end
