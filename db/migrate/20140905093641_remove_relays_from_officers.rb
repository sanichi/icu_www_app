class RemoveRelaysFromOfficers < ActiveRecord::Migration
  def change
    remove_column :officers, :emails, :string
    remove_column :officers, :redirects, :string
  end
end
