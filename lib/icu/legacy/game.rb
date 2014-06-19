module ICU
  module Legacy
    class Game
      include Database
      include Utils

      MAP = {
        pgn_id:        :id,
        pgn_annotator: :annotator,
        pgn_black:     :black,
        pgn_black_elo: :black_elo,
        pgn_date:      :date,
        pgn_eco:       :eco,
        pgn_event:     :event,
        pgn_fen:       :fen,
        pgn_moves:     :moves,
        pgn_ply_count: :ply,
        pgn_pup_id:    :pgn_id,
        pgn_result:    :result,
        pgn_round:     :round,
        pgn_site:      :site,
        pgn_white:     :white,
        pgn_white_elo: :white_elo,
      }

      def synchronize(force=false)
        if existing_games?(force)
          report_error "can't synchronize when games or game journal entries exist unless force is used"
          return
        end
        game_count = 0
        @duplicates = 0
        @other_errors = 0
        old_database.query("SELECT #{MAP.keys.join(", ")} FROM pgn ORDER BY pgn_id").each do |game|
          game_count += 1
          create_game(game)
        end
        puts "old game records processed: #{game_count}"
        puts "new game records created: #{::Game.count}"
        puts "duplicates: #{@duplicates}"
        puts "other_errors: #{@other_errors}"
      end

      private

      def create_game(old_game)
        params = MAP.each_with_object({}) do |(old_attr, new_attr), new_game|
          new_game[new_attr] = old_game[old_attr]
        end
        adjust(params)
        begin
          ::Game.create!(params)
          puts "game #{params[:id]}: #{params[:result]} #{params[:date]} #{params[:white]} - #{params[:black]}"
        rescue => e
          puts "ERROR: could not create game ID #{params[:id]}: #{e.message}"
          if e.message.match(/duplicate|signature/i)
            @duplicates += 1
          else
            @other_errors += 1
          end
        end
      end

      def adjust(params)
        params[:date] = "#{$1}.??.??" if params[:date].match(/\A(\d{4})\.\?\?\.\d\d\z/)
        params[:annotator] = nil if params[:annotator].match(/\A\s*(,|Robot)/)
        params[:annotator] = "W.H.Cozens" if params[:id] == 26839
      end

      def existing_games?(force)
        count = ::Game.count
        changes = JournalEntry.games.count
        case
        when count == 0 && changes == 0
          false
        when force
          puts "old game records deleted: #{::Game.delete_all}"
          puts "old game journal entries deleted: #{JournalEntry.games.delete_all}"
          false
        else
          true
        end
      end
    end
  end
end
