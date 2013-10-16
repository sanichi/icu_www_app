class CreateJournalEntries < ActiveRecord::Migration
  def change
    create_table :journal_entries do |t|
      t.integer  :journalable_id
      t.string   :journalable_type, :action, :column, :by, :ip, limit: 50
      t.string   :from, :to
      t.datetime :created_at
    end

    add_index :journal_entries, [:journalable_id, :journalable_type]
  end
end
