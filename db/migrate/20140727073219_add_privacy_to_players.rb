class AddPrivacyToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :privacy, :string
  end
end
