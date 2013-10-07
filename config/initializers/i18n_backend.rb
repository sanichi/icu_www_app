# Only works if the translations table already exists.
if ActiveRecord::Base.connection.table_exists? "translations"
  # Update the DB translations to reflect changes in the YAML files (unless we're in the test env).
  Translation.update_db unless Rails.env == "test"
  
  # Check that the Redis cache is in sync with the SQL database.
  Translation.check_cache

  # YAML/Simple for English, Redis/KeyValue for Irish.
  I18n.backend = I18n::Backend::Chain.new(I18n::Backend::Simple.new, I18n::Backend::KeyValue.new(Translation.cache, false))
end
