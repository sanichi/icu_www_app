class AddEnabledToRelays < ActiveRecord::Migration
  def change
    add_column :relays, :enabled, :boolean, default: true
  end
end
