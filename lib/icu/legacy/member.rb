module ICU
  module Legacy
    class Member
      include Database

      MAP = {
        mem_id:       :id,
        mem_icu_id:   :icu_id,
        mem_email:    :email,
        mem_password: :encrypted_password,
        mem_salt:     :salt,
        mem_status:   :status,
        mem_expiry:   :expires_on,
        mem_verified: :verified_at,
      }

      def synchronize(force=false)
        if existing_users?(force)
          puts "can't synchronize legacy members unless the users table is empty or force is used"
          return
        end
        member_count = 0
        old_database.query("SELECT #{MAP.keys.join(", ")} FROM members").each do |member|
          member_count += 1
          create_user(member)
        end
        puts "old Member records processed: #{member_count}"
        puts "new User records created: #{User.count}"
      end

      private

      def create_user(member)
        params = MAP.each_with_object({}) do |(mem_attr, user_attr), user|
          user[user_attr] = member[mem_attr]
        end
        MAP.values.each do |user_attr|
          return unless valid?(params, user_attr)
        end
        begin
          User.create!(params)
        rescue => e
          puts "could not create user ID #{params[:id]}: #{e.message}"
        end
      end
      
      def valid?(params, user_attr)
        error = nil
        case user_attr
        when :id
          error = "ID (#{params[:id]}) must be positive integer" unless params[:id].present? && params[:id] > 0
        when :icu_id
          error = "missing or invalid ICU ID for ID #{params[:id]}" unless params[:icu_id].present? && params[:icu_id] > 0
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
        else
          raise ArgumentError.new("invalid user attribute: #{user_attr}")
        end
        puts error if error
        error ? false : true
      end

      def existing_users?(force)
        count = User.count
        case
        when count == 0
          false
        when force
          deleted = User.delete_all
          puts "old User records deleted: #{deleted}"
          false
        else
          true
        end
      end
    end
  end
end
