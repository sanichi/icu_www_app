# Synchronisation tasks to be performed once (then never again) to build the initial version of the new ICU database.
# Run it like this:
#   $ bin/rake sync:all > ~/sync.log     # if performing for the first time, or
#   $ bin/rake sync:all[f] > ~/sync.log  # if redoing because of changes
namespace :sync do
  desc "Convert members from the old ICU database to users in this application"
  task :members, [:force] => :environment do |task, args|
    ICU::Legacy::Member.new.synchronize(args[:force])
  end
  
  desc "Convert clubs from the old ICU database to clubs in this application"
  task :clubs, [:force] => :environment do |task, args|
    ICU::Legacy::Club.new.synchronize(args[:force])
  end

  desc "Convert icu_players from the old ICU database to players in this application"
  task :players, [:force] => :environment do |task, args|
    ICU::Legacy::Player.new.synchronize(args[:force])
  end

  desc "Convert old_players from the ratings database to players in this application"
  task :archive, [:force] => :environment do |task, args|
    ICU::Legacy::Archive.new.synchronize(args[:force])
  end

  desc "Convert icu_player_changes from the old ICU database to journal_entries in this application"
  task :changes, [:force] => :environment do |task, args|
    ICU::Legacy::Change.new.synchronize(args[:force])
  end

  desc "Update player status"
  task :status, [:force] => :environment do |task, args|
    ICU::Legacy::Status.new.update(args[:force])
  end

  desc "Check all synchronized data"
  task :check => :environment do |task, args|
    ICU::Legacy::Check.new.check
  end

  desc "Perform all synchronization tasks"
  task :all, [:force] => [:clubs, :players, :changes, :status, :archive, :members, :check]
end
