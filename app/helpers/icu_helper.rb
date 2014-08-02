module IcuHelper
  def icu_season_menu(selected)
    current = Season.new
    season = current
    seasons = []
    5.times.each do |n|
      date = season.to_s
      if n == 0
        seasons.push ["#{date} (#{t('icu.current_season')})", date]
      else
        seasons.push [date, date]
      end
      season = season.last
    end
    if Date.today.month == 8
      date = current.next.to_s
      seasons.unshift ["#{date} (#{t('icu.next_season')})", date]
    end
    options_for_select(seasons, selected)
  end

  def icu_season_dates(date)
    season = Season.new(date)
    "%s: %s → %s" % [season.to_s, formatted_date(season.start), formatted_date(season.end)]
  end
end
