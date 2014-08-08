# Cleanup old carts. Use force to do so, default is to print which would be deleted.
namespace :cleanup do
  desc "Destroy old empty carts"
  task :empty, [:force] => :environment do |task, args|
    Util::Cleanup.new.empty(args[:force])
  end

  desc "Destroy old unpaid carts and their items"
  task :unpaid, [:force] => :environment do |task, args|
    Util::Cleanup.new.unpaid(args[:force])
  end

  desc "Print stats on old unpaid or empty carts"
  task :stats => :environment do |task|
    Util::Cleanup.new.stats
  end
end
