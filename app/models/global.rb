module Global
  SOURCES = %w[www1 www2]  # indicates whether data comes from the legacy database/website (www1) or this one (www2)
  MIN_YEAR = 1850          # the oldest date before which we can be sure the ICU did not exist (used in validating dates and years)
end
