class CreateRelays < ActiveRecord::Migration
  def change
    create_table :relays do |t|
      t.string   :from, :to, :provider_id, limit: 50
      t.integer  :officer_id

      t.timestamps
    end
  end
end
