module ICU
  module Legacy
    class Archive
      include Database

      MAP = {
        icu_id:     :id,
        first_name: :first_name,
        last_name:  :last_name,
        gender:     :gender,
        dob:        :dob,
        joined:     :joined,
        club:       :club_id,
        rating:     :legacy_rating,
        games:      :legacy_games,
        note:       :note,
      }

      SUSPICIOUS_DOBS = %w/1975-01-02 1976-01-01 1985-01-02 1950-09-01 1985-01-01 1955-01-01 1970-01-01 1977-01-01/

      def synchronize(force=false)
        if existing_archive_players?(force)
          report_error "can't synchronize when archive players exist unless force is used"
          return
        end
        return unless existing_players_and_clubs?

        get_clubs
        @stats = Hash.new { Array.new }

        player_count = 0
        rat_database.query("SELECT #{MAP.keys.join(", ")} FROM old_players where status = 'archived'").each do |player|
          player_count += 1
          create_player(player)
        end

        puts "old player records processed: #{player_count}"
        puts "new player records created: #{::Player.where(source: "archive").count}"

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
          puts "created archive player #{params[:id]}, #{params[:first_name]} #{params[:last_name]}"
        rescue => e
          report_error "could not create player ID #{params[:id]} (#{params[:first_name]} #{params[:last_name]}): #{e.message}"
          add_stat(:problem_records, params[:id])
        end
      end

      def adjust(params, old_player)
        # Add fixed value parameters.
        params[:source] = "archive"
        params[:status] = "inactive"
        params[:fed] = "IRL"
        params[:legacy_rating_type] = "full"

        # Turn club name to ID.
        if params[:club_id].present?
          if @club[params[:club_id]]
            params[:club_id] = @club[params[:club_id]]
            add_stat(:converted_clubs, params[:id])
          else
            params[:club_id] = nil
            add_stat(:unconverted_clubs, params[:id])
          end
        else
          add_stat(:missing_clubs, params[:id])
          params[:club_id] = nil
        end

        # Update links in note.
        if params[:note].present?
          params[:note].gsub!(/\[(\d+)\]\(\/icu_players\/\d+\)/, '[\1](/admin/players/\1)')
          params[:note].gsub!(/\[(\d+)\]\(\/admin\/old_players\/\d+\)/, '[\1](/admin/players/\1)')
          params[:note].gsub!(/with current member/, "with player")
          params[:note].gsub!(/with former member/, "with archive player")
        end

        # Some DOBs can't be trusted (because they are 1st of the month and occur with a
        # suspiciously high frequency compared to others). They probably YOBs or guesses.
        if params[:dob]
          date = params[:dob].to_s
          if SUSPICIOUS_DOBS.include?(date)
            if params[:note].present?
              params[:note].strip!
              params[:note] += "\n\n"
            else
              params[:note] = ""
            end
            params[:note] += "Old records suggest this player was born in #{params[:dob].year}."
            params[:dob] = nil
          end
        end
      end

      def get_clubs
        @club = ::Club.all.each_with_object({}) do |club, hash|
          hash[club.name] = club.id
        end
      end

      def existing_archive_players?(force)
        scope = ::Player.where(source: "archive")
        count = scope.count
        case
        when count == 0
          false
        when force
          puts "old archive player records deleted: #{scope.delete_all}"
          false
        else
          true
        end
      end

      def existing_players_and_clubs?
        if ::Player.count == 0
          report_error "can't synchronize archive players before nornal players have been synchronized"
          false
        elsif ::Club.count == 0
          report_error "can't synchronize archive players before clubs have been synchronized"
          false
        else
          true
        end
      end

      def add_stat(key, id)
        @stats[key] = @stats[key] << id
      end

      def dump_stats
        max = @stats.keys.inject(0) { |m, k| m = k.length if k.length > m; m }
        puts "stats:"
        @stats.keys.sort.each do |name|
          ids = @stats[name]
          size = ids.size
          ids = ids.sort
          ids = ids.sort[0,10] << "..." << ids[-10,10] if size > 20
          puts "  %-#{max}s %5d: %s" % [name, size, ids.join(',')]
        end
      end

      def report_error(msg)
        puts "ERROR: #{msg}"
      end
    end
  end
end
