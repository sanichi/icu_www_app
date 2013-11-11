class AddPhonesToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :home_phone, :string, limit: 30
    add_column :players, :mobile_phone, :string, limit: 30
    add_column :players, :work_phone, :string, limit: 30
  end
end
