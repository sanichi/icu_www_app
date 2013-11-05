class AddEmailToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :email, :string, limit: 50
  end
end
