class AddAutoPayToRefunds < ActiveRecord::Migration
  def change
    add_column :refunds, :automatic, :boolean, default: true
  end
end
