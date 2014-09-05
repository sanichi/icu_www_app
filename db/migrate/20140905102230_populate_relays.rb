class PopulateRelays < ActiveRecord::Migration
  def up
    Relay.all.each { |relay| relay.delete }
    Officer.all.each do |officer|
      officer.role.split("_").each do |role|
        officer.relays.create!(from: "#{role}@icu.ie")
      end
    end
  end

  def down
    Relay.all.each { |relay| relay.delete }
  end
end
