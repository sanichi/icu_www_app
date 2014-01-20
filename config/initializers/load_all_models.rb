# Models that include Journalable each create a different scope on JournalEntry when loaded.
# The problem is that the scope can be called before the model class is loaded.
# To avoid this, all models are pre-loaded. The downside is that it makes test and dev slower.
Dir.glob("#{Rails.root}/app/models/*.rb").each do |file|
  require_dependency file
end
