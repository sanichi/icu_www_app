# Synchronisation tasks to be performed once (then never again) to build the initial version
# of the new ICU database (www_production) from data in the old ICU database (icuadmi_main)
# and also the ratings database (ratings_production).
# Run them like this:
#   $ bin/rake sync:all > ~/sync.log     # if performing for the first time, or
#   $ bin/rake sync:all[f] > ~/sync.log  # if redoing because of changes
# The actual migration took place on 2014-07-23 and the log files from these tasks
# are stored in the following places:
#   * aontas:~/bak/migration/sync (ICU server)
#   * abidjan:~/Projects/Migration/sync (MO's desktop)
#   * mogadishu:~/Projects/Migration/sync (MO's laptop)
# A copy of the legacy database has also been retained on MO's computers and in the file:
#   * aontas:~/bak/migration/www1/icuadmi_main_2014-07-23.sql.gz
# After the migration, the tasks in this file (except check which is still OK to run) were
# all disabled. This code is kept for posterity in case any detective work, in conjunction
# with the log files and the last state of the legacy database, is ever required.
namespace :sync do
  desc "Convert icuadmi_main/clubs to www_production/clubs"
  task :clubs, [:force] => :environment do |task, args|
    ICU::Legacy::Club.new.synchronize(args[:force])
  end

  desc "Convert icuadmi_main/icu_players www_production/players"
  task :players, [:force] => :environment do |task, args|
    ICU::Legacy::Player.new.synchronize(args[:force])
  end

  desc "Convert icuadmi_main/icu_player_changes to www_production/journal_entries"
  task :changes, [:force] => :environment do |task, args|
    ICU::Legacy::Change.new.synchronize(args[:force])
  end

  desc "Update www_production/player/status"
  task :status, [:force] => :environment do |task, args|
    ICU::Legacy::Status.new.update(args[:force])
  end

  desc "Convert ratings_production/old_players to www_production/players"
  task :archive, [:force] => :environment do |task, args|
    ICU::Legacy::Archive.new.synchronize(args[:force])
  end

  desc "Convert icuadmi_main/members to www_production/users"
  task :members, [:force] => :environment do |task, args|
    ICU::Legacy::Member.new.synchronize(args[:force])
  end

  desc "Convert icuadmi_main/{subscriptions,subs_offline,subs_forlife} to www_production/subscriptions"
  task :subscriptions, [:force] => :environment do |task, args|
    ICU::Legacy::Subscription.new.synchronize(args[:force])
  end

  desc "Convert icuadmi_main/events to www_production/events"
  task :events, [:force] => :environment do |task, args|
    ICU::Legacy::Event.new.synchronize(args[:force])
  end

  desc "Convert icuadmi_main/images to www_production/images"
  task :images => :environment do |task|
    ICU::Legacy::Image.new.synchronize
  end

  desc "Convert legacy files in prd/htd/misc to www_production/downloads"
  task :downloads, [:force] => :environment do |task, args|
    ICU::Legacy::Download.new.synchronize(args[:force])
  end

  desc "Convert icuadmi_main/tournaments to www_production/tournaments"
  task :tournaments, [:force] => :environment do |task, args|
    ICU::Legacy::Tournament.new.synchronize(args[:force])
  end

  desc "Convert icuadmi_main/tournaments to www_production/champions"
  task :champions, [:force] => :environment do |task, args|
    ICU::Legacy::Champion.new.synchronize(args[:force])
  end

  desc "Convert icuadmi_main/pgn_uploads to www_production/pgns"
  task :pgns, [:force] => :environment do |task, args|
    ICU::Legacy::Pgn.new.synchronize(args[:force])
  end

  desc "Convert icuadmi_main/pgn to www_production/games"
  task :games, [:force] => :environment do |task, args|
    ICU::Legacy::Game.new.synchronize(args[:force])
  end

  desc "Convert icuadmi_main/articles to www_production/articles"
  task :articles, [:force] => :environment do |task, args|
    ICU::Legacy::Article.new.synchronize(args[:force])
  end

  desc "Convert icuadmi_main/news to www_production/news"
  task :news, [:force] => :environment do |task, args|
    ICU::Legacy::News.new.synchronize(args[:force])
  end

  desc "Check all synchronized data"
  task :check => :environment do |task|
    ICU::Legacy::Check.new.check
  end

  desc "Perform all synchronization tasks"
  task :all, [:force] => %i[clubs players changes status archive members subscriptions events images downloads tournaments champions articles news check]
end
