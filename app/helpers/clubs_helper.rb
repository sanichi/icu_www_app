module ClubsHelper
  def club_active_search_menu(selected)
    statuses = ["active", "inactive"].map { |s| [t("club.#{s}"), s] }
    statuses.push [t("either"), ""]
    options_for_select(statuses, selected)
  end

  def province_search_menu(selected)
    provinces = Ireland.provinces.map { |p| [t("ireland.prov.#{p}"), p] }
    provinces.unshift [t("ireland.prov.any"), ""]
    options_for_select(provinces, selected)
  end

  def county_search_menu(selected)
    counties = Ireland.counties.map { |c| [t("ireland.co.#{c}"), c] }
    counties.unshift [t("ireland.co.any"), ""]
    options_for_select(counties, selected)
  end
end
