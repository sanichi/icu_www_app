class CreateMailEvents < ActiveRecord::Migration
  def change
    create_table :mail_events do |t|
      t.integer   :accepted, :rejected, :delivered, :failed, :opened, :clicked, :unsubscribed, :complained, :stored, :total, :other, default: 0
      t.integer   :page, limit: 1
      t.date      :date
      t.datetime  :first_time, :last_time

      t.timestamps
    end

    add_index :mail_events, :date
  end
end
