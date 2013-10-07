module ICU
  module Legacy
    class Club
      include Database

      MAP = {
        club_id:        :id,
        club_name:      :name,
        club_status:    :active,
        club_province:  :province,
        club_county:    :county,
        club_city:      :city,
        club_district:  :district,
        club_address:   :address,
        club_meetings:  :meetings,
        club_contact:   :contact,
        club_phone:     :phone,
        club_email:     :email,
        club_web:       :web,
        club_latitude:  :latitude,
        club_longitude: :longitude,
      }

      def synchronize(force=false)
        if existing_clubs?(force)
          report_error "can't synchronize legacy clubs unless the clubs table is empty or force is used"
          return
        end
        club_count = 0
        old_database.query("SELECT #{MAP.keys.join(", ")} FROM clubs").each do |club|
          club_count += 1
          create_club(club)
        end
        puts "old Club records processed: #{club_count}"
        puts "new Club records created: #{::Club.count}"
      end

      private

      def create_club(old_club)
        params = MAP.each_with_object({}) do |(old_attr, new_attr), new_club|
          new_club[new_attr] = old_club[old_attr]
        end
        params[:active] = params[:active] == "active"
        params[:province].downcase!
        params[:county].downcase!
        begin
          ::Club.create!(params)
          puts "created Club #{params[:id]}, #{params[:name]}"
        rescue => e
          report_error "could not create club ID #{params[:id]} (#{params[:name]}): #{e.message}"
        end
      end

      def existing_clubs?(force)
        count = ::Club.count
        case
        when count == 0
          false
        when force
          deleted = ::Club.delete_all
          puts "old Club records deleted: #{deleted}"
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
