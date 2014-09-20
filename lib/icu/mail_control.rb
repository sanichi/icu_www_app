module ICU
  class MailControl
    def check(print=false)
      stop, reason = check_predictions(20.0)               # prediction for end of month
      stop, reason = check_for_spike(2.0, 24) unless stop  # cost of last 24 hours (ignoring allowance)
      stop, reason = check_for_spike(0.2, 1) unless stop   # cost of last hour (ignoring allowance)
      if stop
        Relay.toggle_all(false)
        if print
          puts "EMERGENCY STOP: #{reason}"
        else
          ::Failure.log("MailControlEmergencyStop", details: reason) # failures are highligted when webmaster signs in
        end
      else
        if print
          puts "no emergency stop required"
        end
      end
    rescue => e
      if print
        puts "ERROR: #{e.class}, #{e.message}\n#{e.backtrace[0..3].join("\n")}"
      else
        ::Failure.log("MailControlCheck", exception: e.class.to_s, message: e.message, date: date.to_s, details: e.backtrace[0..3].join("\n"))
      end
    end

    private

    def check_predictions(tolerance)
      month = ::MailEvent.month
      if month.predicted_cost > tolerance
        [true, "monthly tolerance (#{tolerance}) exceeded by prediction (#{month.predicted_cost})"]
      else
        [false, nil]
      end
    end

    def check_for_spike(tolerance, hours)
      count, cost = ::Util::Mailgun.charge_for_last(hours)
      if cost > tolerance
        [true, "#{hours}-hour tolerance (#{tolerance}) exceeded by #{cost} for #{count} events"]
      else
        [false, nil]
      end
    end
  end
end
