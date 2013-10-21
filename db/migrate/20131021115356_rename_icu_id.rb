class RenameIcuId < ActiveRecord::Migration
  change_table :users do |t|
    t.rename :icu_id, :player_id
  end
end
