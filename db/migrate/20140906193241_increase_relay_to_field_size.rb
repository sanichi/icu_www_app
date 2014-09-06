class IncreaseRelayToFieldSize < ActiveRecord::Migration
  def change
    change_column :relays, :to, :string
  end
end
