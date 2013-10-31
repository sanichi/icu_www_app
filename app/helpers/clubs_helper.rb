module ClubsHelper
  def club_active_menu(selected, default="either")
    statuses = [[t("club.active"), "true"], [t("club.inactive"), "false"]]
    statuses.push [t(default), ""] if default
    options_for_select(statuses, selected)
  end

  def club_county_menu(selected, default="ireland.co.any")
    counties = Ireland.counties.map { |c| [t("ireland.co.#{c}"), c] }
    counties.unshift [t(default), ""]
    options_for_select(counties, selected)
  end

  def club_menu(selected, opt={})
    clubs = Club.all.map { |c| [c.name, c.id] }
    clubs.unshift [t("none"), 0] if opt[:none]
    clubs.unshift [t("player.any_club"), ""] if opt[:any]
    options_for_select(clubs, selected)
  end

  def club_province_menu(selected, default="ireland.prov.any")
    provinces = Ireland.provinces.map { |p| [t("ireland.prov.#{p}"), p] }
    provinces.unshift [t(default), ""]
    options_for_select(provinces, selected)
  end
end
