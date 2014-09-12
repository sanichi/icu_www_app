class Admin::JournalEntriesController < ApplicationController
  def index
    authorize! :index, JournalEntry
    @entries = JournalEntry.search(params, admin_journal_entries_path, remote: request.xhr?)
    if request.xhr?
      render "changes.js"
    else
      flash.now[:warning] = t("no_matches") if @entries.count == 0
      save_last_search(@entries, :journal_entries)
    end
  end

  def show
    @entry = JournalEntry.find(params[:id])
    authorize! :show, @entry
    @prev_next = Util::PrevNext.new(session, JournalEntry, params[:id], admin: true)
  end
end
