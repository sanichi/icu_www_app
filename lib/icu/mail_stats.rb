module ICU
  class MailStats
    def report(print=false)
      begin
        start_date = ::Date.today.days_ago(32)
        stats = ::Util::Mailgun.stats(start_date) # stats[date][event] = count
        month = ::Util::ChargeMonth.new(::Util::Mailgun::PROFILE)
        text = text(stats, month)
      rescue => e
        text = "ERROR: #{e.class}, #{e.message}\n#{e.backtrace[0..3].join("\n")}"
      end
      if print
        puts text
      else
        ::IcuMailer.mail_stats(text).deliver_now
      end
    end

    private

    def text(stats, month)
      events = stats.values.map(&:keys).flatten.uniq.sort # unique event names from Mailgun data
      augment(events, stats, month)
      header, format = format(events)
      text = []
      text.push header
      text.push "-" * header.length
      stats.keys.sort.reverse.each do |date|
        values = events.map { |event| stats[date][event] }
        values.unshift date
        text.push format % values
      end
      text.unshift ""
      text.unshift "cost (%s) %15.2f" % [month.provider_profile.currency, month.predicted_cost]
      text.unshift "counts %19d" % month.predicted_count
      text.unshift "--------------------------"
      text.unshift "predictions for #{month.end_date}"
      text.unshift ""
      text.join("\n")
    end

    def format(events)
      lengths = events.each_with_object({}) do |event, hash|
        length = event.length
        length = 5 if length < 5
        hash[event] = length
      end
      headers = []
      headers.push "%-10s" % ["date"]
      events.each { |event| headers.push "%-#{lengths[event]}s" % [event] }
      formats = []
      formats.push "%-10s"
      events.each { |event| formats.push "%-#{lengths[event]}d" }
      [headers.join("  "), formats.join("  ")]
    end
    
    # Add counts for virtual events "cumulative" and "chargeable" to stats.
    # Add "chargeable" counts to the ChargeMonth so it can make predictions.
    def augment(events, stats, month)
      events.push "chargeable"
      events.push "cumulative"
      cumulative = 0
      stats.keys.sort.each do |date|
        numbers = stats[date]
        numbers["chargeable"] = ::Util::Mailgun::CHARGEABLE.map{ |event| numbers[event] }.reduce(&:+)
        if month.includes?(date)
          cumulative += numbers["chargeable"]
          if date != month.today.to_s # stats for today will be incomplete and shouldn't be used for prediction
            month.add_data(date, numbers["chargeable"])
          end
        end
        numbers["cumulative"] = cumulative
      end
    end
  end
end
