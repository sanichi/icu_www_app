module ICU
  module Legacy
    class Player
      include Database

      MAP = {
        plr_id:           :id,
        plr_id_dup:       :player_id,
        plr_first_name:   :first_name,
        plr_last_name:    :last_name,
        plr_sex:          :gender,
        plr_date_born:    :dob,
        plr_date_joined:  :joined,
        plr_date_died:    nil,
        plr_deceased:     :status,
        plr_club_id:      :club_id,
        plr_fed:          :fed,
        plr_title:        :player_title,
        plr_email:        :email,
        plr_address1:     nil,
        plr_address2:     nil,
        plr_address3:     nil,
        plr_address4:     nil,
        plr_phone_home:   :home_phone,
        plr_phone_mobile: :mobile_phone,
        plr_phone_work:   :work_phone,
      }

      def synchronize(force=false)
        if existing_players?(force)
          report_error "can't synchronize when players or player journal entries exist unless force is used"
          return
        end
        player_count = 0
        @stats = Hash.new { Array.new }
        old_database.query("SELECT #{MAP.keys.join(", ")} FROM icu_players").each do |player|
          player_count += 1
          create_player(player)
        end
        puts "old player records processed: #{player_count}"
        puts "new player records created: #{::Player.count}"
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
          puts "created player #{params[:id]}, #{params[:first_name]} #{params[:last_name]}"
        rescue => e
          report_error "could not create player ID #{params[:id]} (#{params[:first_name]} #{params[:last_name]}): #{e.message}"
          add_stat(:problem_ids, params[:id])
        end
      end

      def adjust(params, old_player)
        params[:dob] = nil if params[:dob].to_s == "1950-01-01"
        params[:joined] = nil if params[:joined].to_s == "1975-01-01"
        params[:source] = "import"
        params[:status] = params[:status] == "Yes" ? "deceased" : "active"
        params[:arbiter_title] = case params[:id]
                                 when 507  then "FA" # GG
                                 when 1538 then "FA" # BS
                                 when 1733 then "NA" # PF
                                 when 1875 then "FA" # TJ
                                 when 1393 then "IA" # JQ
                                 when 3000 then "IA" # KOC
                                 when 5160 then "FA" # RD
                                 when 5983 then "NA" # PM
                                 else nil
                                 end
        params[:trainer_title] = case params[:id]
                                 when 3000  then "FST" # KOC
                                 when 5193  then "FI"  # KOF
                                 when 5601  then "FI"  # GM
                                 when 10499 then "DI"  # MT
                                 when 12165 then "FI"  # BB
                                 when 12275 then "DI"  # COM
                                 else nil
                                 end
        params[:address] = (1..4).map{ |n| old_player["plr_address#{n}".to_sym] }.reject{ |v| v.blank? }.map{ |s| s.strip }.join(", ")
        # Chuck out invalid phone numbers. Leave it to validation to canonicalize the good ones.
        %w[home mobile work].each do |type|
          param = "#{type}_phone".to_sym
          phone = Phone.new(params[param])
          unless phone.parsed?
            params[param] = nil
            add_stat(:phones_bad, params[:id]) unless phone.blank?
          end
        end
        # TODO: add date died to note
      end

      def existing_players?(force)
        count = ::Player.count
        changes = JournalEntry.players.count
        case
        when count == 0 && changes == 0
          false
        when force
          deleted = ::Player.delete_all
          puts "old player records deleted: #{deleted}"
          deleted = JournalEntry.players.delete_all
          puts "old player journal entries deleted: #{deleted}"
          false
        else
          true
        end
      end

      def add_stat(key, id)
        @stats[key] = @stats[key] << id
      end

      def gather_stats(player, params)
        add_stat(:name_adjustments,    player.id) unless player.first_name == params[:first_name] && player.last_name == params[:last_name]
        add_stat(:unknown_dob,         player.id) if player.dob.nil?
        add_stat(:unknown_join_date,   player.id) if player.joined.nil?
        add_stat(:unknown_gender,      player.id) if player.gender.nil?
        add_stat(:unknown_federation,  player.id) if player.fed.nil?
        add_stat(:deceased_players,    player.id) if player.deceased?
        add_stat(:duplicate_players,   player.id) if player.duplicate?
        add_stat(:female_players,      player.id) if player.gender == "F"
        add_stat(:club_players,        player.id) if player.club_id.present?
        add_stat(:irish_players,       player.id) if player.fed.present? && player.fed == "IRL"
        add_stat(:foreign_players,     player.id) if player.fed.present? && player.fed != "IRL"
        add_stat(:player_emails,       player.id) if player.email.present?
        add_stat(:player_addresses,    player.id) if player.address.present?
        add_stat(:federation_changes,  player.id) if params[:fed].present? && player.fed.present? && params[:fed] != player.fed
        add_stat(:federation_deletes,  player.id) if params[:fed].present? && player.fed.nil?
        add_stat(:phones_home,         player.id) if player.home_phone.present?
        add_stat(:phones_mobile,       player.id) if player.mobile_phone.present?
        add_stat(:phones_work,         player.id) if player.work_phone.present?
        add_stat(:phones_none,         player.id) if player.home_phone.blank? && player.mobile_phone.blank? && player.work_phone.blank?
      end

      def dump_stats
        max = @stats.keys.inject(0) { |m, k| m = k.length if k.length > m; m }
        puts "stats (#{max}):"
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
