module ICU
  module Legacy
    class Status
      include Database

      def update(force=false)
        unless existing_players?
          report_error "can't update without some players"
          return
        end
        if existing_updates?(force)
          report_error "can't update without resetting previous updates unless force is used"
          return
        end

        # Prepare to gather statistics.
        @stats = Hash.new { 0 }

        # Gather data we need.
        total_players
        current_players
        subscribers
        recent_players
        legacy_players
        high_legacy_tournaments
        high_legacy_games
        active_exceptions
        foreign_exceptions

        # Now do some calculations.
        inactive_players
        foreign_players

        # Perform the updates.
        update_players

        # Print statistics.
        dump_stats
        
        # Debug a single player.
        # debug(16689)
      end

      private
      
      def debug(id)
        puts id
        puts "  #{@players[id] ? 'T' : 'F'} player"
        puts "  #{@inactive_players[id] ? 'T' : 'F'} inactive"
        puts "  #{@foreign_players[id] ? 'T' : 'F'} foreign"
        puts "  #{@subscribers[id] ? 'T' : 'F'} subscriber"
        puts "  #{@recent_players[id] ? 'T' : 'F'} recent player"
        puts "  #{@legacy_players[id] ? 'T' : 'F'} legacy player"
        puts "  #{@high_legacy_tournaments[id] ? 'T' : 'F'} high legacy tournaments"
        puts "  #{@high_legacy_games[id] ? 'T' : 'F'} high legacy games"
        puts "  #{@active_exceptions[id] ? 'T' : 'F'} active exception"
        puts "  #{@foreign_exceptions[id] ? 'T' : 'F'} foreign exception"
      end

      def update_players
        @players.each do |id, player|
          if @foreign_players[id]
            player.update_column("status", "foreign")
            add_stat(:set_foreign)
          elsif @inactive_players[id]
            player.update_column("status", "inactive")
            add_stat(:set_inactive)
          end
        end
      end

      def inactive_players
        @inactive_players = {}
        @players.keys.each do |id|
          next if @subscribers[id]
          next if @recent_players[id]
          next if @legacy_players[id]
          next if @active_exceptions[id]
          @inactive_players[id] = true
        end
        add_stat(:players_inactive, @inactive_players.length)
      end

      def foreign_players
        @foreign_players = {}
        @players.keys.each do |id|
          next if @players[id].fed == "IRL"
          next if @players[id].club_id.present?
          next if @players[id].dob.present?
          next if id < 7300
          next if @subscribers[id]
          next if @high_legacy_tournaments[id]
          next if @high_legacy_games[id]
          next if @foreign_exceptions[id]
          @foreign_players[id] = true
        end
        add_stat(:players_foreign, @foreign_players.length)
      end

      def total_players
        add_stat(:players_total, ::Player.where(player_id: nil).count)
      end

      def current_players
        @players = ::Player.where(player_id: nil).where(status: "active").each_with_object({}) do |player, hash|
          hash[player.id] = player
          add_stat(:players_current)
        end
      end

      def subscribers
        @subscribers = {}
        [online_subscribers_sql, offline_subscribers_sql, life_members_sql].each do |sql|
          old_database.query(sql).each do |subscriber|
            @subscribers[subscriber[:id]] = true
          end
        end
        add_stat(:subscibers, @subscribers.length)
      end

      def recent_players
        @recent_players = {}
        rat_database.query(recent_players_sql).each do |player|
          @recent_players[player[:id]] = true
        end
        add_stat(:players_recent, @recent_players.length)
      end

      def legacy_players
        @legacy_players = {}
        rat_database.query(legacy_players_sql).each do |player|
          @legacy_players[player[:id]] = true
        end
        add_stat(:players_legacy, @legacy_players.length)
      end

      def high_legacy_tournaments
        @high_legacy_tournaments = {}
        rat_database.query(high_legacy_tournaments_sql).each do |player|
          @high_legacy_tournaments[player[:id]] = true
        end
        add_stat(:players_high_tournaments, @high_legacy_tournaments.length)
      end

      def high_legacy_games
        @high_legacy_games = {}
        rat_database.query(high_legacy_games_sql).each do |player|
          @high_legacy_games[player[:id]] = true
        end
        add_stat(:players_high_games, @high_legacy_games.length)
      end

      def active_exceptions
        @active_exceptions =
        {
          13364 => true, # active in India
        }
        add_stat(:exceptions_active, @active_exceptions.length)
      end

      def foreign_exceptions
        @foreign_exceptions =
        {
        }
        add_stat(:exceptions_foreign, @foreign_exceptions.length)
      end

      def existing_players?
        ::Player.count > 0
      end

      def existing_updates?(force)
        scope = ::Player.where(player_id: nil).where("status NOT IN ('active', 'deceased')")
        count = scope.count
        case
        when count == 0
          false
        when force
          scope.update_all(status: "active")
          puts "old player records reset: #{count}"
          false
        else
          true
        end
      end

      def add_stat(key, number=1)
        @stats[key] += number
      end

      def dump_stats
        max = @stats.keys.inject(0) { |m, k| m = k.length if k.length > m; m }
        puts "stats:"
        @stats.keys.sort.each do |name|
          puts "  %-#{max}s %5d" % [name, @stats[name]]
        end
      end

      def report_error(msg)
        puts "ERROR: #{msg}"
      end

      def online_subscribers_sql
        <<-EOS
        SELECT
          DISTINCT(sub_icu_id) AS id
        FROM
          subscriptions,
          payments
        WHERE
          pay_id = sub_pay_id AND
          pay_status != 'Created'
        EOS
      end

      def offline_subscribers_sql
        <<-EOS
        SELECT
          DISTINCT(sof_icu_id) AS id
        FROM
          subs_offline
        EOS
      end

      def life_members_sql
        <<-EOS
        SELECT
          DISTINCT(sfl_icu_id) AS id
        FROM
          subs_forlife
        EOS
      end

      def recent_players_sql
        <<-EOS
        SELECT
          DISTINCT(icu_id) AS id
        FROM
          players p,
          tournaments t
        WHERE
          t.id = p.tournament_id AND
          t.rorder IS NOT NULL AND
          p.icu_id IS NOT NULL
        EOS
      end

      def legacy_players_sql
        <<-EOS
        SELECT
          DISTINCT(icu_player_id) AS id
        FROM
          old_rating_histories
        EOS
      end

      def high_legacy_tournaments_sql
        <<-EOS
        SELECT icu_player_id AS id
        FROM
          (
            SELECT
              icu_player_id, count(*) AS tournaments
            FROM
              old_rating_histories
            GROUP BY
              icu_player_id
          ) AS counts
        WHERE
          tournaments > 2
        EOS
      end

      def high_legacy_games_sql
        <<-EOS
        SELECT
          icu_player_id AS id
        FROM
          (
            SELECT
              icu_player_id, max(games) AS counts
            FROM
              old_rating_histories
            GROUP BY
              icu_player_id
          ) AS game_players
        WHERE
          counts > 1
        EOS
      end
    end
  end
end
