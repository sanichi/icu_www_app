module ActiveHelper
  def active_menu(selected, default="either")
    acts = [[t("active"), "true"], [t("inactive"), "false"]]
    acts.push [t(default), ""]
    options_for_select(acts, selected)
  end
end
