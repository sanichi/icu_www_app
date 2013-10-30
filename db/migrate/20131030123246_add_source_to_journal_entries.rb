class AddSourceToJournalEntries < ActiveRecord::Migration
  def change
    add_column :journal_entries, :source, :string, limit: 8, default: "www2"
  end
end
