class AddLegacyRatingsToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :legacy_rating, :integer, limit: 2
    add_column :players, :legacy_rating_type, :string, limit: 20
    add_column :players, :legacy_games, :integer, limit: 2
  end
end
