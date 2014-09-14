module ICU
  class MailEvents
    def save(print=false)
      date = ::Date.today.yesterday
      events = ::Util::Mailgun.events(date)
      if print
        puts events.inspect
      else
        events.each do |data|
          page = data.delete("page")
          event = ::MailEvent.where(date: date, page: page).first
          if event
            ::MailEvent::CODES.keys.each { |atr| data[atr.to_s] = 0 unless data.has_key?(atr.to_s) }
            data.each { |atr,val| event.send("#{atr}=", val) }
            event.save! if event.changed?
          else
            data["date"] = date
            data["page"] = page
            ::MailEvent.create!(data)
          end
        end
      end
    rescue => e
      if print
        puts e.inspect
      else
        ::Failure.log("MailEventsReport", exception: e.class.to_s, message: e.message, date: date.to_s, details: e.backtrace[0..5].join("\n"))
      end
    end
  end
end
