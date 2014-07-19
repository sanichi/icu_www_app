module ICU
  module Legacy
    class Champion
      include Database
      include Utils

      MAP = {
        trn_id:      nil,
        trn_details: :winners,
        trn_title:   :category,
        trn_year:    :year,
      }

      def synchronize(force=false)
        if existing_champions?(force)
          report_error "can't synchronize when champions or champion journal entries exist unless force is used"
          return
        end

        champion_count = 0
        query = <<EOQ
SELECT #{MAP.keys.join(", ")}
FROM tournaments
WHERE trn_title = "Irish Championship" OR trn_title = "Irish Championships" OR trn_title LIKE "Irish Ladies%"
ORDER BY trn_year
EOQ

        old_database.query(query).each do |champion|
          champion_count += 1
          create_champion(champion)
        end
        puts "old champion records processed: #{champion_count}"
        puts "new champion records created: #{::Champion.count}"
      end

      private

      def create_champion(old_champion)
        params = MAP.each_with_object({}) do |(old_attr, new_attr), new_champion|
          if new_attr
            new_champion[new_attr] = old_champion[old_attr]
          end
        end
        begin
          adjust(params, old_champion)
          ::Champion.create!(params)
          puts "created champion #{params[:year]}|#{params[:category]}|#{params[:winners]}|#{params[:notes]}"
        rescue => e
          report_error "could not create champion from tournament #{old_champion[:trn_id]}: #{e.message}"
        end
      end

      def adjust(params, old)
        params[:category] = params[:category].include?("Ladies") ? "women" : "open"
        if params[:winners].match(/\AChampions?:\s+([^\r\n]+)/)
          winners = $1
          winners.gsub!(/<.*/, "")
          winners.trim!
          winners.sub!(/\.\z/, "")
          params[:winners] = winners
        else
          params[:winners] = nil
        end
        unless [105, 113, 115, 116, 117, 663, 664].include?(old[:trn_id])
          params[:notes] = "[TRN:#{old[:trn_id]}:Details]"
        end
        case
          when params[:year] == 2014 && params[:category] == "open"  then params[:notes] = "[RTN:474:Cross table], Chess Today [DLD:91:article]"
          when params[:year] == 2014 && params[:category] == "women" then params[:notes] = "[RTN:483:Cross table]"
          when params[:year] == 2013 && params[:category] == "open"  then params[:notes] += ", [RTN:311:cross table]"
          when params[:year] == 2013 && params[:category] == "women" then params[:notes] += ", [RTN:327:cross table]"
          when params[:year] == 2012 && params[:category] == "open"  then params[:notes] += ", [RTN:156:cross table]"
          when params[:year] == 2012 && params[:category] == "women" then params[:notes] += ", [RTN:224:cross table]"
          when params[:year] == 1953 && params[:category] == "women" then params[:notes] = "Miss Hilda Chater beat Miss Beth Cassidy 3-0 in the play-off"
        end
      end

      def existing_champions?(force)
        count = ::Champion.count
        changes = JournalEntry.champions.count
        case
        when count == 0 && changes == 0
          false
        when force
          puts "old champion records deleted: #{::Champion.delete_all}"
          puts "old champion journal entries deleted: #{JournalEntry.champions.delete_all}"
          ActiveRecord::Base.connection.execute("ALTER TABLE champions AUTO_INCREMENT = 1")
          false
        else
          true
        end
      end
    end
  end
end
