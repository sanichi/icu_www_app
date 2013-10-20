module ICU
  module Legacy
    class Player
      include Database

      MAP = {
        plr_id:          :id,
        plr_id_dup:      :player_id,
        plr_first_name:  :first_name,
        plr_last_name:   :last_name,
        plr_sex:         :gender,
        plr_date_born:   :dob,
        plr_date_joined: :joined,
        plr_date_died:   nil,
        plr_deceased:    :deceased,
      }

      def synchronize(force=false)
        if existing_players?(force)
          report_error "can't synchronize legacy players unless the players table is empty or force is used"
          return
        end
        player_count = 0
        @stats = Hash.new { Array.new }
        old_database.query("SELECT #{MAP.keys.join(", ")} FROM icu_players").each do |player|
          player_count += 1
          create_player(player)
        end
        puts "old Player records processed: #{player_count}"
        puts "new Player records created: #{::Player.count}"
        dump_stats
      end

      private

      def create_player(old_player)
        params = MAP.each_with_object({}) do |(old_attr, new_attr), new_player|
          if new_attr
            new_player[new_attr] = old_player[old_attr]
          end
        end
        begin
          adjust(params, old_player)
          player = ::Player.create!(params)
          gather_stats(player, params)
          puts "created Player #{params[:id]}, #{params[:first_name]} #{params[:last_name]}"
        rescue => e
          report_error "could not create player ID #{params[:id]} (#{params[:first_name]} #{params[:last_name]}): #{e.message}"
        end
      end

      def adjust(params, old_player)
        params[:deceased] = params[:deceased] == "Yes" || old_player[:plr_date_died].present? ? true : false
        params[:dob] = nil if params[:dob].to_s == "1950-01-01"
        params[:joined] = nil if params[:joined].to_s == "1975-01-01"
        params[:source] = "import"
        params[:status] = "active"
        # TODO: add date died to note
      end

      def existing_players?(force)
        count = ::Player.count
        case
        when count == 0
          false
        when force
          deleted = ::Player.delete_all
          puts "old Player records deleted: #{deleted}"
          false
        else
          true
        end
      end

      def add_stat(key, id)
        @stats[key] = @stats[key] << id
      end

      def gather_stats(player, params)
        add_stat(:name_adjustments, player.id) unless player.first_name == params[:first_name] && player.last_name == params[:last_name]
        add_stat(:unknown_dob, player.id) if player.dob.blank?
        add_stat(:unknown_join_date, player.id) if player.joined.blank?
        add_stat(:unknown_gender, player.id) if player.gender.blank?
        add_stat(:deceased_players, player.id) if player.deceased
        add_stat(:duplicate_players, player.id) if player.duplicate?
        add_stat(:female_players, player.id) if player.gender == "F"
      end

      def dump_stats
        puts "stats:"
        @stats.each do |name, ids|
          size = ids.size
          ids = ids.sort
          ids = ids.sort[0,10] << "..." << ids[-10,10] if size > 20
          puts "  #{name} (#{size}): #{ids.join(',')}"
        end
      end

      def report_error(msg)
        puts "ERROR: #{msg}"
      end
    end
  end
end
