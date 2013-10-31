module TranslationsHelper
  def translation_active_menu(selected)
    categories = [["All translations", ""]]
    categories << ["Translatable", "creatable"]
    categories << ["Retranslatable", "updatable"]
    categories << ["Editable", "editable"]
    categories << ["Deletable", "deletable"]
    options_for_select(categories, selected)
  end
end
