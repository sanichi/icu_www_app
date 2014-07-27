module Global
  # Indicates whether data comes from the legacy database and website (www1) or this one (www2).
  SOURCES = %w[www1 www2]

  # Simple regular expression for email addresses.
  EMAIL = '[^\s@]+@[^\s@]+'
  EMAIL_RGX = /\A#{EMAIL}\z/

  # The oldest date before which we can be sure the ICU did not exist (used in validating dates and years).
  MIN_YEAR = 1850

  # A list of ICU page names (keys), in order, where ICU info is stored plus optional comments for the index page (values).
  ICU_PAGES = {
    constitution: "",
    membership_byelaws: "rules applying to individual members of the ICU",
    code_of_conduct: "the behaviour expected of members and corresponding disciplinary procedures",
    eligibility_criteria: "stipulates who can play for Ireland in international events",
    junior_eligibility_criteria: "stipulates who can play for Ireland in junior international events",
    selection_committee: "terms of reference for this sub-committee",
    ncc_rules: "",
    affiliation_byelaws: "rules for bodies such as the Connaught, Leinster and Munster Chess Unions",
    officer_roles: "descriptions of the various roles within the ICU committee",
    allegro_rules: "rules for all-moves-in-X type time controls",
  }

  # A list of help page names.
  HELP_PAGES = %w[
    index accounts data_protection membership
    offline_payments shortcuts
  ]
end
