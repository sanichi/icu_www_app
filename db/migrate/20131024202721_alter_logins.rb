class AlterLogins < ActiveRecord::Migration
  change_table :logins do |t|
    t.remove :email
    t.change :ip, :string, limit: 50
  end
end
