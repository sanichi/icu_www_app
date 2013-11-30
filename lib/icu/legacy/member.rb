module ICU
  module Legacy
    class Member
      include Database

      MAP = {
        mem_id:       :id,
        mem_icu_id:   :player_id,
        mem_email:    :email,
        mem_password: :encrypted_password,
        mem_salt:     :salt,
        mem_status:   :status,
        mem_expiry:   :expires_on,
        mem_verified: :verified_at,
        mem_pin:      :season_ticket,
      }

      def synchronize(force=false)
        if existing_users?(force)
          report_error "can't synchronize when users or user journal entries exist unless force is used"
          return
        end
        member_count = 0
        old_database.query("SELECT #{MAP.keys.join(", ")} FROM members WHERE mem_status = 'ok'").each do |member|
          member_count += 1
          create_user(member)
        end
        puts "old member records processed: #{member_count}"
        puts "new user records created: #{User.count}"
      end

      private

      def create_user(member)
        params = MAP.each_with_object({}) do |(mem_attr, user_attr), user|
          user[user_attr] = member[mem_attr]
        end
        MAP.values.each do |user_attr|
          return unless valid?(params, user_attr)
        end
        params.delete(:season_ticket)
        begin
          case params[:id]
          when 1   then params[:roles] = "admin"       # Mark
          when 4   then params[:roles] = "translator"  # Gearoidin
          when 634 then params[:roles] = "translator"  # Una
          end
          User.create!(params)
          puts "created user #{params[:id]}, #{params[:email]}"
        rescue => e
          report_error "could not create user ID #{params[:id]}: #{e.message}"
        end
      end

      def valid?(params, user_attr)
        error = nil
        case user_attr
        when :id
          error = "ID (#{params[:id]}) must be positive integer" unless params[:id].present? && params[:id] > 0
        when :player_id
          error = "missing or invalid ICU ID (#{params[:player_id]}) for ID #{params[:id]}" unless params[:player_id].present? && params[:player_id] > 0
        when :email
          error = "missing email for ID #{params[:id]}" unless params[:email].present?
        when :encrypted_password
          error = "missing or invalid encrypted password for ID #{params[:id]}" unless params[:encrypted_password].to_s.length == 32
        when :salt
          error = "missing or invalid salt for ID #{params[:id]}" unless params[:salt].to_s.length == 32
        when :status
          params[:status] = "OK" if params[:status] == "ok"
          error = "invalid status (#{params[:status]}) for ID #{params[:id]}" unless params[:status] == "OK"
        when :expires_on
          error = "missing expiry date for ID #{params[:id]}" unless params[:expires_on].present?
        when :verified_at
          params[:verified_at] = Time.now if params[:verified_at].nil? && params[:status].match(/\AOK\z/i)
          error = "missing verification date for ID #{params[:id]}" unless params[:verified_at].present?
        when :season_ticket
          error = "missing season ticket for ID #{params[:id]}" unless params[:season_ticket].present?
          unless error
            ticket = SeasonTicket.new(params[:season_ticket])
            if ticket.valid?
              if ticket.icu_id != params[:player_id]
                error = "mismatched ICU ID between ticket (#{ticket.icu_id}) and record (#{params[:player_id]}) for ID #{params[:id]}"
              elsif ticket.expires_on != params[:expires_on].to_s
                error = "mismatched expiry date between ticket (#{ticket.expires_on}) and record (#{params[:expires_on]}) for ID #{params[:id]}"
              end
            else
              error = "invalid season ticket (#{params[:season_ticket]}) for ID #{params[:id]}"
            end
          end
        else
          raise ArgumentError.new("invalid user attribute: #{user_attr}")
        end
        report_error(error) if error
        error ? false : true
      end

      def existing_users?(force)
        count = User.count
        changes = JournalEntry.users.count
        case
        when count == 0 && changes == 0
          false
        when force
          deleted = User.delete_all
          puts "old user records deleted: #{deleted}"
          deleted = JournalEntry.users.delete_all
          puts "old user journal entries deleted: #{deleted}"
          false
        else
          true
        end
      end

      def report_error(msg)
        puts "ERROR: #{msg}"
      end
    end
  end
end
