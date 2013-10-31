class AddClubToPlayer < ActiveRecord::Migration
  def change
    add_column :players, :club_id, :integer
  end
end
