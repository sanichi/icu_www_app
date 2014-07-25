# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140725095834) do

  create_table "articles", force: true do |t|
    t.string   "access",     limit: 20
    t.boolean  "active"
    t.string   "author",     limit: 100
    t.string   "category",   limit: 20
    t.text     "text"
    t.string   "title",      limit: 100
    t.boolean  "markdown",               default: true
    t.integer  "user_id"
    t.integer  "year",       limit: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "articles", ["access"], name: "index_articles_on_access", using: :btree
  add_index "articles", ["active"], name: "index_articles_on_active", using: :btree
  add_index "articles", ["author"], name: "index_articles_on_author", using: :btree
  add_index "articles", ["category"], name: "index_articles_on_category", using: :btree
  add_index "articles", ["title"], name: "index_articles_on_title", using: :btree
  add_index "articles", ["user_id"], name: "index_articles_on_user_id", using: :btree
  add_index "articles", ["year"], name: "index_articles_on_year", using: :btree

  create_table "bad_logins", force: true do |t|
    t.string   "email"
    t.string   "encrypted_password", limit: 32
    t.string   "ip",                 limit: 50
    t.datetime "created_at"
  end

  add_index "bad_logins", ["created_at"], name: "index_bad_logins_on_created_at", using: :btree
  add_index "bad_logins", ["email"], name: "index_bad_logins_on_email", using: :btree
  add_index "bad_logins", ["ip"], name: "index_bad_logins_on_ip", using: :btree

  create_table "carts", force: true do |t|
    t.string   "status",             limit: 20,                          default: "unpaid"
    t.decimal  "total",                          precision: 9, scale: 2
    t.decimal  "original_total",                 precision: 9, scale: 2
    t.string   "payment_method",     limit: 20
    t.string   "payment_ref",        limit: 50
    t.string   "confirmation_email", limit: 50
    t.string   "confirmation_error"
    t.text     "confirmation_text"
    t.boolean  "confirmation_sent",                                      default: false
    t.string   "payment_name",       limit: 100
    t.integer  "user_id"
    t.datetime "payment_completed"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "carts", ["confirmation_email"], name: "index_carts_on_confirmation_email", using: :btree
  add_index "carts", ["payment_method"], name: "index_carts_on_payment_method", using: :btree
  add_index "carts", ["payment_name"], name: "index_carts_on_payment_name", using: :btree
  add_index "carts", ["status"], name: "index_carts_on_status", using: :btree
  add_index "carts", ["user_id"], name: "index_carts_on_user_id", using: :btree

  create_table "champions", force: true do |t|
    t.string   "category",   limit: 20
    t.string   "notes",      limit: 140
    t.string   "winners"
    t.integer  "year",       limit: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "champions", ["category"], name: "index_champions_on_category", using: :btree
  add_index "champions", ["winners"], name: "index_champions_on_winners", using: :btree
  add_index "champions", ["year"], name: "index_champions_on_year", using: :btree

  create_table "clubs", force: true do |t|
    t.string   "county",     limit: 20
    t.string   "name",       limit: 50
    t.string   "city",       limit: 50
    t.string   "district",   limit: 50
    t.string   "contact",    limit: 50
    t.string   "email",      limit: 50
    t.string   "phone",      limit: 50
    t.string   "address",    limit: 100
    t.string   "web",        limit: 100
    t.string   "meet"
    t.boolean  "active"
    t.decimal  "lat",                    precision: 10, scale: 7
    t.decimal  "long",                   precision: 10, scale: 7
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "clubs", ["active"], name: "index_clubs_on_active", using: :btree
  add_index "clubs", ["city"], name: "index_clubs_on_city", using: :btree
  add_index "clubs", ["county"], name: "index_clubs_on_county", using: :btree
  add_index "clubs", ["name"], name: "index_clubs_on_name", using: :btree

  create_table "downloads", force: true do |t|
    t.string   "access",            limit: 20
    t.string   "data_file_name"
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.datetime "data_updated_at"
    t.string   "description",       limit: 150
    t.string   "www1_path",         limit: 128
    t.integer  "user_id"
    t.integer  "year",              limit: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "downloads", ["access"], name: "index_downloads_on_access", using: :btree
  add_index "downloads", ["data_content_type"], name: "index_downloads_on_data_content_type", using: :btree
  add_index "downloads", ["description"], name: "index_downloads_on_description", using: :btree
  add_index "downloads", ["user_id"], name: "index_downloads_on_user_id", using: :btree
  add_index "downloads", ["www1_path"], name: "index_downloads_on_www1_path", using: :btree
  add_index "downloads", ["year"], name: "index_downloads_on_year", using: :btree

  create_table "episodes", force: true do |t|
    t.integer  "article_id"
    t.integer  "series_id"
    t.integer  "number",     limit: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "episodes", ["article_id"], name: "index_episodes_on_article_id", using: :btree
  add_index "episodes", ["number"], name: "index_episodes_on_number", using: :btree
  add_index "episodes", ["series_id"], name: "index_episodes_on_series_id", using: :btree

  create_table "events", force: true do |t|
    t.boolean  "active"
    t.string   "category",           limit: 25
    t.string   "contact",            limit: 50
    t.string   "email",              limit: 50
    t.string   "flyer_file_name"
    t.string   "flyer_content_type"
    t.integer  "flyer_file_size"
    t.datetime "flyer_updated_at"
    t.decimal  "lat",                            precision: 10, scale: 7
    t.string   "location",           limit: 100
    t.decimal  "long",                           precision: 10, scale: 7
    t.string   "name",               limit: 75
    t.string   "note",               limit: 512
    t.string   "phone",              limit: 25
    t.decimal  "prize_fund",                     precision: 8,  scale: 2
    t.string   "source",             limit: 8,                            default: "www2"
    t.date     "start_date"
    t.date     "end_date"
    t.string   "url",                limit: 75
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "events", ["active"], name: "index_events_on_active", using: :btree
  add_index "events", ["category"], name: "index_events_on_category", using: :btree
  add_index "events", ["end_date"], name: "index_events_on_end_date", using: :btree
  add_index "events", ["location"], name: "index_events_on_location", using: :btree
  add_index "events", ["name"], name: "index_events_on_name", using: :btree
  add_index "events", ["start_date"], name: "index_events_on_start_date", using: :btree
  add_index "events", ["user_id"], name: "index_events_on_user_id", using: :btree

  create_table "fees", force: true do |t|
    t.string   "type",              limit: 40
    t.string   "name",              limit: 100
    t.decimal  "amount",                        precision: 9, scale: 2
    t.decimal  "discounted_amount",             precision: 9, scale: 2
    t.string   "years",             limit: 7
    t.integer  "year",              limit: 2
    t.integer  "days",              limit: 2
    t.date     "start_date"
    t.date     "end_date"
    t.date     "sale_start"
    t.date     "sale_end"
    t.date     "age_ref_date"
    t.date     "discount_deadline"
    t.integer  "min_age",           limit: 1
    t.integer  "max_age",           limit: 1
    t.integer  "min_rating",        limit: 2
    t.integer  "max_rating",        limit: 2
    t.string   "url"
    t.boolean  "active",                                                default: false
    t.boolean  "player_required",                                       default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fees", ["active"], name: "index_fees_on_active", using: :btree
  add_index "fees", ["end_date"], name: "index_fees_on_end_date", using: :btree
  add_index "fees", ["name"], name: "index_fees_on_name", using: :btree
  add_index "fees", ["sale_end"], name: "index_fees_on_sale_end", using: :btree
  add_index "fees", ["sale_start"], name: "index_fees_on_sale_start", using: :btree
  add_index "fees", ["start_date"], name: "index_fees_on_start_date", using: :btree
  add_index "fees", ["type"], name: "index_fees_on_type", using: :btree

  create_table "games", force: true do |t|
    t.string   "annotator",  limit: 50
    t.string   "black",      limit: 50
    t.integer  "black_elo",  limit: 2
    t.string   "date",       limit: 10
    t.string   "eco",        limit: 3
    t.string   "event",      limit: 50
    t.string   "fen",        limit: 100
    t.text     "moves"
    t.integer  "pgn_id"
    t.integer  "ply",        limit: 2
    t.string   "result",     limit: 3
    t.string   "round",      limit: 7
    t.string   "signature",  limit: 32
    t.string   "site",       limit: 50
    t.string   "white",      limit: 50
    t.integer  "white_elo",  limit: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "games", ["black"], name: "index_games_on_black", using: :btree
  add_index "games", ["date"], name: "index_games_on_date", using: :btree
  add_index "games", ["eco"], name: "index_games_on_eco", using: :btree
  add_index "games", ["event"], name: "index_games_on_event", using: :btree
  add_index "games", ["result"], name: "index_games_on_result", using: :btree
  add_index "games", ["signature"], name: "index_games_on_signature", using: :btree
  add_index "games", ["white"], name: "index_games_on_white", using: :btree

  create_table "images", force: true do |t|
    t.string   "data_file_name"
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.datetime "data_updated_at"
    t.string   "caption"
    t.string   "dimensions"
    t.string   "credit",            limit: 100
    t.string   "source",            limit: 8,   default: "www2"
    t.integer  "year",              limit: 2
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "images", ["caption"], name: "index_images_on_caption", using: :btree
  add_index "images", ["credit"], name: "index_images_on_credit", using: :btree
  add_index "images", ["user_id"], name: "index_images_on_user_id", using: :btree
  add_index "images", ["year"], name: "index_images_on_year", using: :btree

  create_table "items", force: true do |t|
    t.string   "type",           limit: 40
    t.integer  "player_id"
    t.integer  "fee_id"
    t.integer  "cart_id"
    t.string   "description"
    t.string   "player_data"
    t.date     "start_date"
    t.date     "end_date"
    t.decimal  "cost",                        precision: 9, scale: 2
    t.string   "status",         limit: 20,                           default: "unpaid"
    t.string   "source",         limit: 8,                            default: "www2"
    t.string   "payment_method", limit: 20
    t.string   "notes",          limit: 1000,                         default: "--- []\n"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "items", ["cart_id"], name: "index_items_on_cart_id", using: :btree
  add_index "items", ["end_date"], name: "index_items_on_end_date", using: :btree
  add_index "items", ["fee_id"], name: "index_items_on_fee_id", using: :btree
  add_index "items", ["payment_method"], name: "index_items_on_payment_method", using: :btree
  add_index "items", ["player_id"], name: "index_items_on_player_id", using: :btree
  add_index "items", ["source"], name: "index_items_on_source", using: :btree
  add_index "items", ["start_date"], name: "index_items_on_start_date", using: :btree
  add_index "items", ["status"], name: "index_items_on_status", using: :btree
  add_index "items", ["type"], name: "index_items_on_type", using: :btree

  create_table "journal_entries", force: true do |t|
    t.integer  "journalable_id"
    t.string   "journalable_type", limit: 50
    t.string   "action",           limit: 50
    t.string   "column",           limit: 50
    t.string   "by"
    t.string   "ip",               limit: 50
    t.string   "from"
    t.string   "to"
    t.datetime "created_at"
    t.string   "source",           limit: 8,  default: "www2"
  end

  add_index "journal_entries", ["action"], name: "index_journal_entries_on_action", using: :btree
  add_index "journal_entries", ["by"], name: "index_journal_entries_on_by", using: :btree
  add_index "journal_entries", ["column"], name: "index_journal_entries_on_column", using: :btree
  add_index "journal_entries", ["ip"], name: "index_journal_entries_on_ip", using: :btree
  add_index "journal_entries", ["journalable_id", "journalable_type"], name: "index_journal_entries_on_journalable_id_and_journalable_type", using: :btree
  add_index "journal_entries", ["journalable_id"], name: "index_journal_entries_on_journalable_id", using: :btree
  add_index "journal_entries", ["journalable_type"], name: "index_journal_entries_on_journalable_type", using: :btree

  create_table "logins", force: true do |t|
    t.integer  "user_id"
    t.string   "error"
    t.string   "roles"
    t.string   "ip",         limit: 50
    t.datetime "created_at"
  end

  add_index "logins", ["error"], name: "index_logins_on_error", using: :btree
  add_index "logins", ["ip"], name: "index_logins_on_ip", using: :btree
  add_index "logins", ["user_id"], name: "index_logins_on_user_id", using: :btree

  create_table "news", force: true do |t|
    t.boolean  "active"
    t.date     "date"
    t.string   "headline",   limit: 100
    t.text     "summary"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "news", ["active"], name: "index_news_on_active", using: :btree
  add_index "news", ["date"], name: "index_news_on_date", using: :btree
  add_index "news", ["headline"], name: "index_news_on_headline", using: :btree
  add_index "news", ["user_id"], name: "index_news_on_user_id", using: :btree

  create_table "payment_errors", force: true do |t|
    t.integer  "cart_id"
    t.string   "message"
    t.string   "details"
    t.string   "payment_name",       limit: 100
    t.string   "confirmation_email", limit: 50
    t.datetime "created_at"
  end

  add_index "payment_errors", ["cart_id"], name: "index_payment_errors_on_cart_id", using: :btree
  add_index "payment_errors", ["confirmation_email"], name: "index_payment_errors_on_confirmation_email", using: :btree

  create_table "pgns", force: true do |t|
    t.string   "comment"
    t.string   "content_type"
    t.integer  "duplicates",   default: 0
    t.string   "file_name"
    t.integer  "file_size",    default: 0
    t.integer  "game_count",   default: 0
    t.integer  "imports",      default: 0
    t.integer  "lines",        default: 0
    t.string   "problem"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pgns", ["comment"], name: "index_pgns_on_comment", using: :btree
  add_index "pgns", ["file_name"], name: "index_pgns_on_file_name", using: :btree
  add_index "pgns", ["user_id"], name: "index_pgns_on_user_id", using: :btree

  create_table "players", force: true do |t|
    t.string   "first_name",         limit: 50
    t.string   "last_name",          limit: 50
    t.string   "status",             limit: 25
    t.string   "source",             limit: 25
    t.integer  "player_id"
    t.string   "gender",             limit: 1
    t.date     "dob"
    t.date     "joined"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "club_id"
    t.string   "fed",                limit: 3
    t.string   "player_title",       limit: 3
    t.string   "arbiter_title",      limit: 3
    t.string   "trainer_title",      limit: 3
    t.string   "email",              limit: 50
    t.string   "address"
    t.string   "home_phone",         limit: 30
    t.string   "mobile_phone",       limit: 30
    t.string   "work_phone",         limit: 30
    t.text     "note"
    t.integer  "legacy_rating",      limit: 2
    t.string   "legacy_rating_type", limit: 20
    t.integer  "legacy_games",       limit: 2
    t.integer  "latest_rating",      limit: 2
  end

  add_index "players", ["club_id"], name: "index_players_on_club_id", using: :btree
  add_index "players", ["dob"], name: "index_players_on_dob", using: :btree
  add_index "players", ["fed"], name: "index_players_on_fed", using: :btree
  add_index "players", ["first_name", "last_name"], name: "index_players_on_first_name_and_last_name", using: :btree
  add_index "players", ["first_name"], name: "index_players_on_first_name", using: :btree
  add_index "players", ["gender"], name: "index_players_on_gender", using: :btree
  add_index "players", ["joined"], name: "index_players_on_joined", using: :btree
  add_index "players", ["last_name"], name: "index_players_on_last_name", using: :btree
  add_index "players", ["player_id"], name: "index_players_on_player_id", using: :btree
  add_index "players", ["source"], name: "index_players_on_source", using: :btree
  add_index "players", ["status"], name: "index_players_on_status", using: :btree

  create_table "refunds", force: true do |t|
    t.integer  "cart_id"
    t.integer  "user_id"
    t.string   "error"
    t.decimal  "amount",     precision: 9, scale: 2
    t.datetime "created_at"
  end

  add_index "refunds", ["cart_id"], name: "index_refunds_on_cart_id", using: :btree
  add_index "refunds", ["created_at"], name: "index_refunds_on_created_at", using: :btree
  add_index "refunds", ["user_id"], name: "index_refunds_on_user_id", using: :btree

  create_table "series", force: true do |t|
    t.string   "title",      limit: 100
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "series", ["title"], name: "index_series_on_title", using: :btree

  create_table "tournaments", force: true do |t|
    t.boolean  "active"
    t.string   "category",   limit: 20
    t.string   "city",       limit: 50
    t.text     "details"
    t.string   "format",     limit: 20
    t.string   "name",       limit: 80
    t.integer  "year",       limit: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tournaments", ["active"], name: "index_tournaments_on_active", using: :btree
  add_index "tournaments", ["category"], name: "index_tournaments_on_category", using: :btree
  add_index "tournaments", ["city"], name: "index_tournaments_on_city", using: :btree
  add_index "tournaments", ["format"], name: "index_tournaments_on_format", using: :btree
  add_index "tournaments", ["name"], name: "index_tournaments_on_name", using: :btree
  add_index "tournaments", ["year"], name: "index_tournaments_on_year", using: :btree

  create_table "translations", force: true do |t|
    t.string   "locale",      limit: 2
    t.string   "key"
    t.string   "value"
    t.string   "english"
    t.string   "old_english"
    t.string   "user"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "translations", ["active"], name: "index_translations_on_active", using: :btree
  add_index "translations", ["english"], name: "index_translations_on_english", using: :btree
  add_index "translations", ["key"], name: "index_translations_on_key", using: :btree
  add_index "translations", ["user"], name: "index_translations_on_user", using: :btree
  add_index "translations", ["value"], name: "index_translations_on_value", using: :btree

  create_table "user_inputs", force: true do |t|
    t.integer "fee_id"
    t.string  "type",            limit: 40
    t.string  "label",           limit: 100
    t.boolean "required",                                            default: true
    t.integer "max_length",      limit: 2
    t.decimal "min_amount",                  precision: 6, scale: 2, default: 1.0
    t.string  "date_constraint", limit: 30,                          default: "none"
  end

  add_index "user_inputs", ["fee_id"], name: "index_user_inputs_on_fee_id", using: :btree
  add_index "user_inputs", ["type"], name: "index_user_inputs_on_type", using: :btree

  create_table "users", force: true do |t|
    t.string   "email"
    t.string   "roles"
    t.string   "encrypted_password", limit: 32
    t.string   "salt",               limit: 32
    t.string   "status",                        default: "OK"
    t.integer  "player_id"
    t.date     "expires_on"
    t.datetime "verified_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "theme",              limit: 16
    t.string   "locale",             limit: 2,  default: "en"
  end

  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["expires_on"], name: "index_users_on_expires_on", using: :btree
  add_index "users", ["player_id"], name: "index_users_on_player_id", using: :btree
  add_index "users", ["roles"], name: "index_users_on_roles", using: :btree
  add_index "users", ["status"], name: "index_users_on_status", using: :btree
  add_index "users", ["verified_at"], name: "index_users_on_verified_at", using: :btree

end
