class AlterJournalEntries < ActiveRecord::Migration
  change_table :journal_entries do |t|
    t.change :by, :string
  end
end
