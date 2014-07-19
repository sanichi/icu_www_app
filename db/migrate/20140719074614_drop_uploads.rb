class DropUploads < ActiveRecord::Migration
  def up
    drop_table :uploads
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
