class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string   :email, :roles
      t.string   :encrypted_password, :salt, limit: 32
      t.string   :status, default: User::OK
      t.integer  :icu_id
      t.date     :expires_on
      t.datetime :verified_at

      t.timestamps
    end
  end
end
