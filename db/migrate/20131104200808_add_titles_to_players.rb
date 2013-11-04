class AddTitlesToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :player_title, :string, limit: 3
    add_column :players, :arbiter_title, :string, limit: 3
    add_column :players, :trainer_title, :string, limit: 3
  end
end
