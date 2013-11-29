module ICU
  module Legacy
    class Change
      include Database

      MAP = {
        pch_id:     nil,
        pch_plr_id: :journalable_id,
        pch_attr:   :column,
        pch_mem_id: nil,
        pch_name:   :by,
        pch_from:   :from,
        pch_to:     :to,
        pch_date:   :created_at,
      }

      def synchronize(force=false)
        if existing_entries?(force)
          report_error "can't synchronize when player journal entries exist unless force is used"
          return
        end
        unless players_and_users?
          report_error "can't synchronize journal entries unless players and users are present"
          return
        end
        change_count = 0
        @stats = Hash.new { Array.new }
        puts "old journal entry total: #{JournalEntry.count}"
        old_database.query("SELECT #{MAP.keys.join(", ")} FROM icu_player_changes").each do |change|
          if change[:pch_attr].match(/\A(Address|Club|Date of death)/)
            add_stat(:cant_handle, change[:pch_id])
            next
          end
          change_count += 1
          create_entry(change)
        end
        puts "old player change records processed: #{change_count}"
        puts "new journal entry records created: #{JournalEntry.where(source: "www1").count}"
        puts "new journal entry total: #{JournalEntry.count}"
        dump_stats
      end

      private

      def create_entry(change)
        params = MAP.each_with_object({}) do |(old_attr, new_attr), entry|
          if new_attr
            entry[new_attr] = change[old_attr]
          end
        end
        begin
          adjust(params, change)
          entry = JournalEntry.create!(params)
          gather_stats(entry, params)
        rescue => e
          report_error "could not create journal entry for change #{change[:pch_id]}: #{e.message}"
          add_stat(:problem_ids, change[:pch_id])
        end
      end

      def adjust(params, change)
        # Fixed values for this type of JournalEntry.
        params[:source] = "www1"
        params[:action] = "update"
        params[:journalable_type] = "Player"
        
        # The person doing the change.
        if change[:pch_mem_id] > 0
          if user = @users[change[:pch_mem_id]]
            params[:by] = user.signature
          else
            raise "no user for ID #{change[:pch_mem_id]} in change #{change[:pch_id]}"
          end
        else
          unless params[:by].present?
            raise "no user ID or name for change #{change[:pch_id]}"
          end
        end
        
        # Never blanks but nils/nulls.
        params[:from] = nil if params[:from].blank?
        params[:to] = nil if params[:to].blank?
        
        # The column being changed.
        params[:column] =
          case params[:column]
          when "Club"          then "club_id"
          when "Date joined"   then "joined"
          when "Date of birth" then "dob"
          when "Deceased"      then "status"
          when "Email"         then "email"
          when "Federation"    then "fed"
          when "First name(s)" then "first_name"
          when "Gender"        then "gender"
          when "Home phone"    then "home_phone"
          when "Home phome"    then "home_phone"    # spelling mistake in legacy DB
          when "Last name"     then "last_name"
          when "Master ID"     then "player_id"
          when "Mobile"        then "mobile_phone"
          when "Sex"           then "gender"        # spelling mistake in legacy DB
          when "Title"         then "player_title"
          when "Work phone"    then "work_phone"
          when "Work phome"    then "work_phone"    # spelling mistake in legacy DB
          else raise "can't handle column #{params[:column]}"
          end
        
        # Further adjustments.
        if params[:column] == "status"
          params[:from] = params[:from] == "No" ? nil : "deceased"
          params[:to] = params[:to] == "Yes" ? "deceased" : nil
        end
        if params[:column] == "dob"
          params[:from] = nil if params[:from].to_s == "1950-01-01"
          params[:to] = nil if params[:to].to_s == "1950-01-01"
        end
        if params[:column] == "joined"
          params[:from] = nil if params[:from].to_s == "1975-01-01"
          params[:to] = nil if params[:to].to_s == "1975-01-01"
        end
        if params[:column] == "fed"
          params[:from] = nil if params[:from] == "(none)"
        end
      end

      def existing_entries?(force)
        count = JournalEntry.where(source: "www1").count
        case
        when count == 0
          false
        when force
          deleted = JournalEntry.delete_all(source: "www1")
          puts "old journal entries deleted: #{deleted}"
          false
        else
          true
        end
      end

      def players_and_users?
        players = ::Player.count
        users = User.count
        if players > 0 && users > 0
          @users = User.all.each_with_object({}) { |user, hash| hash[user.id] = user }
          true
        else
          false
        end
      end

      def add_stat(key, id)
        @stats[key] = @stats[key] << id
      end

      def gather_stats(entry, params)
        add_stat("changed_#{entry.column}".to_sym, entry.id)
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
