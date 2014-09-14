namespace :mail do
  desc "Email the latest mail stats to the webmaster or just print them"
  task :stats, [:print] => :environment do |task, args|
    ICU::MailStats.new.report(args[:print])
  end
  desc "Save mail events for yesterday to the database, or just print them"
  task :events, [:print] => :environment do |task, args|
    ICU::MailEvents.new.save(args[:print])
  end
end
