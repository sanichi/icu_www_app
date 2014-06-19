module ICU
  module Legacy
    class Pgn
      include Database
      include Utils

      MAP = {
        pup_id:       :id,
        pup_file:     :file_name,
        pup_bytes:    :file_size,
        pup_lines:    :lines,
        pup_games:    :game_count,
        pup_imports:  :imports,
        pup_comment:  :problem,
        pup_dups_db:  :duplicates,
        pup_date:     :created_at,
        pup_mem_id:   :user_id,
      }

      def synchronize(force=false)
        if existing_pgns?(force)
          report_error "can't synchronize when pgns or pgn journal entries exist unless force is used"
          return
        end
        pgn_count = 0
        @empty = []
        old_database.query("SELECT #{MAP.keys.join(", ")} FROM pgn_uploads").each do |pgn|
          pgn_count += 1
          create_pgn(pgn)
        end
        puts "old pgn records processed: #{pgn_count}"
        puts "new pgn records created: #{::Pgn.count}"
        puts "skipped due to empty file and no imports: #{@empty.size} (#{@empty.join(', ')})"
      end

      private

      def create_pgn(old_pgn)
        params = MAP.each_with_object({}) do |(old_attr, new_attr), new_pgn|
          new_pgn[new_attr] = old_pgn[old_attr]
        end
        adjust(params)
        if params[:file_size] == 0 && params[:imports] == 0
          @empty.push(params[:id])
        else
          begin
            ::Pgn.create!(params)
            puts "pgn #{params[:id]}: #{params[:game_count]}, #{params[:imports]}"
          rescue => e
            report_error "could not create pgn ID #{params[:id]}: #{e.message}"
          end
        end
      end

      def adjust(params)
        params[:content_type] = "text/plain"
        if params[:id] == 237
          params[:file_size] = 500
        end
      end

      def existing_pgns?(force)
        count = ::Pgn.count
        changes = JournalEntry.pgns.count
        case
        when count == 0 && changes == 0
          false
        when force
          puts "old pgn records deleted: #{::Pgn.delete_all}"
          puts "old pgn journal entries deleted: #{JournalEntry.pgns.delete_all}"
          false
        else
          true
        end
      end
    end
  end
end
