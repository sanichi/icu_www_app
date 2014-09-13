namespace :mail do
  desc "Email the latest mail stats to the webmaster or just print them"
  task :stats, [:print] => :environment do |task, args|
    ICU::MailStats.new.report(args[:print])
  end
end
