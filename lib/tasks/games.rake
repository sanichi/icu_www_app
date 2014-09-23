namespace :pgn do
  desc "Email the latest mail stats to the webmaster or just print them"
  task :db, [:force] => :environment do |_, args|
    ICU::PGN.new.database(args[:force])
  end
end
