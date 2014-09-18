module Util
  class ChargeMonth
    attr_reader :start_date, :end_date, :currency

    def initialize(today: Date.today, start_day: 24, free: 10000, cost: 0.0005, currency: "USD")
      raise ArgumentError.new("invalid start day (#{start_day})") unless start_day >= 1 && start_day <= 31

      # Work out the start and end date of the month we're in.
      if today.day >= start_day
        @start_date = Date.new(today.year, today.month, start_day)
        @end_date = @start_date.months_since(1)
        @end_date = @end_date - 1 unless @end_date.day < start_day
      else
        begin
          @end_date = Date.new(today.year, today.month, start_day - 1)
        rescue ArgumentError
          @end_date = Date.new(today.year, today.month, 1).end_of_month
        end
        last_month = today.months_ago(1)
        begin
          @start_date = Date.new(last_month.year, last_month.month, start_day)
        rescue ArgumentError
          @start_date = last_month.end_of_month
        end

        # For making predictions.
        @data = Hash.new
        @free = free
        @cost = cost
        @currency = currency
      end
    end

    def includes?(date)
      date = Date.parse(date.to_s) unless date.is_a?(Date)
      date >= start_date && date <= end_date
    end

    def days
      (@end_date - @start_date).to_i + 1
    end

    def add_data(date, count)
      if includes?(date)
        @data[date.to_s] = count
        @predicted_count = nil
        @predicted_cost = nil
      end
    end

    def predicted_count
      @predicted_count ||= @data.empty?? 0 : (@data.values.reduce(&:+) * days) / @data.size
    end

    def predicted_cost
      return @predicted_cost if @predicted_cost.present?
      count = predicted_count
      total = count <= @free ? 0.0 : (count - @free) * @cost
      @predicted_cost = total.round(2)
    end

    def status # bootstrap label class
      predicted_cost < 5.0 ? "success" : (predicted_cost < 10.0 ? "warning" : "danger")
    end
  end
end