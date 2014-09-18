module ICU
  class MailStats
    def report(print=false)
      begin
        start_date = ::Date.today.days_ago(32)
        stats = ::Util::Mailgun.stats(start_date)
        month = ::Util::ChargeMonth.new(::Util::Mailgun::MONTH_START, today: ::Date.today)
        text = text(stats, month)
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

    def text(stats, month)
      events = stats.values.map(&:keys).flatten.uniq.sort
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
      text.unshift "cost (%s) %15.2f" % [month.currency, month.predicted_cost]
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

    def augment(events, stats, month)
      events.push "chargeable"
      events.push "cumulative"
      cumulative = 0
      stats.keys.sort.each do |date|
        numbers = stats[date]
        numbers["chargeable"] = ::Util::Mailgun::CHARGEABLE.map{ |event| numbers[event] }.reduce(&:+)
        if month.includes?(date)
          cumulative += numbers["chargeable"]
          month.add_data(date, numbers["chargeable"])
        end
        numbers["cumulative"] = cumulative
      end
    end
  end
end
