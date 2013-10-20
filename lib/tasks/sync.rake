namespace :sync do
  desc "Synchronize members from the old ICU database to users in this application (only do this once)"
  task :users, [:force] => :environment do |task, args|
    ICU::Legacy::Member.new.synchronize(args[:force])
  end
  
  desc "Synchronize clubs from the old ICU database to clubs in this application (only do this once)"
  task :clubs, [:force] => :environment do |task, args|
    ICU::Legacy::Club.new.synchronize(args[:force])
  end

  desc "Synchronize icu_players from the old ICU database to players in this application (only do this once)"
  task :players, [:force] => :environment do |task, args|
    ICU::Legacy::Player.new.synchronize(args[:force])
  end

  desc "Check all synchronized data"
  task :check => :environment do |task, args|
    ICU::Legacy::Check.new.check
  end
end
