class AddNoteToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :note, :text
  end
end
