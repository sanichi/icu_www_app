class AddUserPreferences < ActiveRecord::Migration
  def change
    add_column :users, :theme, :string, limit: 16
    add_column :users, :locale, :string, limit: 2, default: "en"
  end
end
