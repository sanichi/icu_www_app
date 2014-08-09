class AddActiveToFailures < ActiveRecord::Migration
  def change
    add_column :failures, :active, :boolean, default: true
  end
end
