module Admin::JournalEntriesHelper
  def type_search_menu(selected)
    types = JournalEntry.pluck("DISTINCT journalable_type").sort.map{|t| [t, t]}
    types.unshift(["Any type", ""])
    options_for_select(types, selected)
  end

  def jl_action_search_menu(selected)
    actions = JournalEntry::ACTIONS.map{|a| [a.capitalize, a]}
    actions.unshift(["Any action", ""])
    options_for_select(actions, selected)
  end
end
