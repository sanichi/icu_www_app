namespace :sync do
  desc "Synchronize members from the old ICU database to users in this application (only do this once)"
  task :users, [:force] => :environment do |task, args|
    ICU::Legacy::Member.new.synchronize(args[:force])
  end
end
