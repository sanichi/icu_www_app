class AddAddressToPlayer < ActiveRecord::Migration
  def change
    add_column :players, :address, :string
  end
end
