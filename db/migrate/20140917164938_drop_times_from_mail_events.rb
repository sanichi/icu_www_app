class DropTimesFromMailEvents < ActiveRecord::Migration
  def up
    remove_column :mail_events, :page
    remove_column :mail_events, :first_time
    remove_column :mail_events, :last_time
    add_column :mail_events, :pages, :integer, limit: 1

    MailEvent.delete_all
    MailEvent.create!(date: "2014-09-16", pages: 4, accepted: 513, delivered: 250, failed: 264, opened: 156, total: 1083)
    MailEvent.create!(date: "2014-09-15", pages: 5, accepted: 506, delivered: 245, failed: 263, opened: 386, total: 1400)
    MailEvent.create!(date: "2014-09-14", pages: 2, accepted: 170, delivered:  90, failed:   0, opened: 251, total:  511)
    MailEvent.create!(date: "2014-09-13", pages: 2, accepted: 151, delivered:  78, failed:  13, opened: 185, total:  427)
  end

  def down
    add_column :mail_events, :page, :integer, limit: 1
    add_column :mail_events, :first_time, :datetime
    add_column :mail_events, :last_time, :datetime
    remove_column :mail_events, :pages, :integer, limit: 1
  end
end
