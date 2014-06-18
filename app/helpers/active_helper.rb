module ActiveHelper
  def active_menu(selected, top=false)
    acts = [[t("active"), "true"], [t("inactive"), "false"]]
    if top
      acts.unshift [t("either"), ""]
    else
      acts.push [t("either"), ""]
    end
    options_for_select(acts, selected)
  end
end
