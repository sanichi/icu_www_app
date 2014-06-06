module ClubsHelper
  def club_county_menu(selected, default="ireland.co.any")
    counties = Ireland.counties.map { |c| [t("ireland.co.#{c}"), c] }
    counties.unshift [t(default), ""]
    options_for_select(counties, selected)
  end

  def club_menu(selected, opt={})
    clubs = Club.all.map { |c| [c.name, c.id] }
    clubs.unshift [t("player.no_club"), 0] if opt[:none]
    clubs.unshift [t("player.any_club"), ""] if opt[:any]
    options_for_select(clubs, selected)
  end

  def club_province_menu(selected, default="ireland.prov.any")
    provinces = Ireland.provinces.map { |p| [t("ireland.prov.#{p}"), p] }
    provinces.unshift [t(default), ""]
    options_for_select(provinces, selected)
  end
end
