# Simple for English and KeyValue for Irish.
#I18n.backend = I18n::Backend::Chain.new(I18n::Backend::Simple.new, I18n::Backend::KeyValue.new(Translation, false))

# Except for the test environment, update the DB translations to reflect changes in the YAML files.
#Translation.update_db unless Rails.env == "test"
