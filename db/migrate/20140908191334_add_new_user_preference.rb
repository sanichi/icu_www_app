class AddNewUserPreference < ActiveRecord::Migration
  def change
    add_column :users, :hide_header, :boolean, default: false
  end
end
