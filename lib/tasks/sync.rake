namespace :sync do
  desc "Convert members from the old ICU database to users in this application (only do this once)"
  task :members, [:force] => :environment do |task, args|
    ICU::Legacy::Member.new.synchronize(args[:force])
  end
  
  desc "Convert clubs from the old ICU database to clubs in this application (only do this once)"
  task :clubs, [:force] => :environment do |task, args|
    ICU::Legacy::Club.new.synchronize(args[:force])
  end

  desc "Convert icu_players from the old ICU database to players in this application (only do this once)"
  task :players, [:force] => :environment do |task, args|
    ICU::Legacy::Player.new.synchronize(args[:force])
  end

  desc "Convert icu_player_changes from the old ICU database to journal_entries in this application (only do this once)"
  task :changes, [:force] => :environment do |task, args|
    ICU::Legacy::Change.new.synchronize(args[:force])
  end

  desc "Update player status (only do this once)"
  task :status, [:force] => :environment do |task, args|
    ICU::Legacy::Status.new.update(args[:force])
  end

  desc "Check all synchronized data"
  task :check => :environment do |task, args|
    ICU::Legacy::Check.new.check
  end
end
