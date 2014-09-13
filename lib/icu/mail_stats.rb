module ICU
  class MailStats
    def report(print=false)
      begin
        start_date = ::Date.today.days_ago(32)
        stats = ::Util::Mailgun.stats(start_date)
        text = text(stats)
      rescue => e
        text = "ERROR: #{e.class}, #{e.message}"
      end
      if print
        puts text
      else
        ::IcuMailer.mail_stats(text).deliver
      end
    end

    private

    def text(stats)
      events = stats.values.map(&:keys).flatten.uniq.sort
      augment(events, stats)
      header, format = format(events)
      text = []
      text.push header
      text.push "-" * header.length
      stats.keys.sort.reverse.each do |date|
        values = events.map { |event| stats[date][event] }
        values.unshift date
        text.push format % values
      end
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

    def augment(events, stats)
      events.push "chargeable"
      events.push "cumulative"
      started = false
      cumulative = 0
      stats.keys.sort.each do |date|
        numbers = stats[date]
        numbers["chargeable"] = ::Util::Mailgun::CHARGEABLE.map{ |event| numbers[event] }.reduce(&:+)
        if ::Util::Mailgun.charge_reset(date)
          if started
            cumulative = 0
          else
            started = true
          end
        end
        cumulative += numbers["chargeable"] if started
        numbers["cumulative"] = cumulative
      end
    end
  end
end
