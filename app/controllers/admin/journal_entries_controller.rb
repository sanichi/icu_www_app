class Admin::JournalEntriesController < ApplicationController
  def index
    authorize! :index, JournalEntry
    @entries = JournalEntry.search(params, admin_journal_entries_path)
    flash.now[:warning] = t("no_matches") if @entries.count == 0
    save_last_search(:admin, :journal_entries)
  end

  def show
    @entry = JournalEntry.find(params[:id])
    authorize! :show, @entry
  end
end
