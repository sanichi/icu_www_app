class AddLatestRatingToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :latest_rating, :integer, limit: 2
  end
end
