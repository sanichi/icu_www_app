module ICU
  module Legacy
    class Event
      include Database

      MAP = {
        event_contact:    :contact,
        event_email:      :email,
        event_end:        :end_date,
        event_form:       nil,
        event_id:         :id,
        event_latitude:   :lat,
        event_location:   :location,
        event_longitude:  :long,
        event_mem_id:     :user_id,
        event_name:       :name,
        event_note:       :note,
        event_phone:      :phone,
        event_prize_fund: :prize_fund,
        event_start:      :start_date,
        event_status:     :active,
        event_type:       :category,
        event_web:        :url,
      }

      def synchronize(force=false)
        if existing_events?(force)
          report_error "can't synchronize when events or event journal entries exist unless force is used"
          return
        end
        @path = tmp_directory
        event_count = 0
        cancelled = 0
        old_database.query("SELECT #{MAP.keys.join(", ")} FROM events").each do |event|
          event_count += 1
          if event[:event_name].match(/cancelled/i)
            cancelled += 1
          else
            create_event(event)
          end
        end
        puts "old event records processed: #{event_count}"
        puts "cancelled events skipped: #{cancelled}"
        puts "new event records created: #{::Event.count}"
        ::Event::CATEGORIES.each do |cat|
          puts "events of type '#{cat}': #{::Event.where(category: cat).count}"
        end
        [true, false].each do |active|
          puts "events active=#{active}: #{::Event.where(active: active).count}"
        end
        puts "events with flyers': #{::Event.where.not(flyer_file_name: nil).count}"
        puts "events without flyers': #{::Event.where(flyer_file_name: nil).count}"
      end

      private

      def tmp_directory
        path = Rails.root + "tmp" + "www1" + "events"
        FileUtils.mkdir_p path
        path
      end

      def create_event(old_event)
        params = MAP.each_with_object({}) do |(old_attr, new_attr), new_event|
          if new_attr
            new_event[new_attr] = old_event[old_attr]
          end
        end
        begin
          adjust(params, old_event)
          ::Event.create!(params)
          puts "created event #{params[:id]}, #{params[:name]}"
        rescue => e
          report_error "could not create event ID #{params[:id]} (#{params[:name]}): #{e.message}"
        end
      end

      def adjust(params, old)
        params[:active] = old[:event_status] == "online"
        params[:category] = "women" if old[:event_type] == "irish" && old[:event_name].match(/women/i)
        params[:prize_fund] = nil if params[:prize_fund] == 0.0
        params[:source] = "www1"
        if old[:event_form].present?
          flyer = get_old_event_flyer(old)
          params[:flyer] = flyer if flyer
        end
      end

      def get_old_event_flyer(old)
        return if [49, 77, 133, 135, 304, 402].include?(old[:event_id]) # These flyers have known problems
        raise "can't handle #{old[:event_form]}" unless old[:event_form].match(/\A(pdf|doc|rtf)\z/)
        file = "#{old[:event_id]}.#{old[:event_form]}"
        path = @path + file
        File.delete(path) if File.exists?(path)
        `wget http://www.icu.ie/events/forms/#{file} --quiet -O #{path}`
        raise "#{path} doesn't exist" unless File.exist?(path)
        File.new(path)
      end

      def existing_events?(force)
        count = ::Event.count
        changes = JournalEntry.events.count
        case
        when count == 0 && changes == 0
          false
        when force
          puts "old event records deleted: #{::Event.delete_all}"
          puts "old event journal entries deleted: #{JournalEntry.events.delete_all}"
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
