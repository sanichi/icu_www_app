module EventsHelper
  def event_active_menu(selected)
    options_for_select(%w[active inactive all].map { |c| [t(c), c] }, selected)
  end

  def event_category_menu(selected)
    cats = Event::CATEGORIES.map { |cat| [t("event.category.#{cat}"), cat] }
    options_for_select(cats, selected)
  end

  def event_month_menu(selected)
    months = (1..12).map { |m| m = "%02d" % m; [t("month.m#{m}"), m] }
    options_for_select(months, selected)
  end

  def event_year_menu(selected)
    years = (2005..Date.today.year).to_a.reverse.map { |y| [y, y] }
    options_for_select(years, selected)
  end
end
