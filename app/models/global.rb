module Global
  # Indicates whether data comes from the legacy database and website (www1) or this one (www2).
  SOURCES = %w[www1 www2]

  # The oldest date before which we can be sure the ICU did not exist (used in validating dates and years).
  MIN_YEAR = 1850

  # The minimum DOB and join dates for today's players.
  MIN_DOB = Date.new(1900, 1, 1)
  MIN_JOINED = Date.new(1960, 1, 1)

  # A list of ICU documentation page names (keys), in order, plus optional comments for the index page (values).
  ICU_DOCS = {
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

  # A list of other ICU page names (which don't have notes).
  ICU_PAGES = %w[documents index life_members officers subscribers]

  # A list of help page names.
  HELP_PAGES = %w[
    accounts header index membership pgn privacy profile
    downloads images markdown officers offline_payments shortcuts treasurer
  ]

  # Validator for full URLs.
  def self.valid_url?(string)
    url = URI(string)
    url.scheme.match(/\Ahttps?\z/) && url.host.present?
  rescue
    false
  end

  # Validator for email addresses.
  def self.valid_email?(string)
    email = Mail::Address.new(string)
    email.local.present? && email.domain.present?
  rescue
    false
  end
end
