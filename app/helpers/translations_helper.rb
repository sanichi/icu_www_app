module TranslationsHelper
  def translation_active_menu(selected)
    options_for_select(["All translations", "Action required", "In use", "No longer used"], selected)
  end
end
