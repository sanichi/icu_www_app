class CreateBadLogins < ActiveRecord::Migration
  def change
    create_table :bad_logins do |t|
      t.string   :email
      t.string   :encrypted_password, limit: 32
      t.string   :ip, limit: 50
      t.datetime :created_at
    end
  end
end
