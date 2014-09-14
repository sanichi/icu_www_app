module Util
  class Mailgun
    STOP = "stop()"
    CATCH_ALL = "catch_all()"
    CHARGEABLE = %w[received delivered dropped]
    MAX_EVENTS_PAGES = 10
    MAX_EVENTS_PER_PAGE = 300

    def self.validate(address)
      result = client("public").get "address/validate", { address: address }
      result.to_h["is_valid"]
    end

    def self.routes
      client.get("routes").to_h["items"].each_with_object({}) do |route, hash|
        next if route["expression"] == CATCH_ALL
        if route["expression"].to_s.match(/\Amatch_recipient\(["'](\w+@icu\.ie)["']\)\z/)
          from = $1
        else
          raise "couldn't parse expression in #{route}"
        end
        forwards = []
        enabled = true
        if route["actions"].is_a?(Array)
          enabled = false if route["actions"][0] == STOP
          route["actions"].each do |action|
            next if action == STOP
            if action.match(/\Aforward\(["']([^,"'\s@]+@[^,"'\s@]+)["']\)\z/)
              forwards.push($1)
            else
              raise "unrecognised action in #{route}"
            end
          end
        else
          raise "expected array of actions in #{route}"
        end
        if route["id"].present?
          id = route["id"]
        else
          raise "couldn't get ID for #{route}"
        end
        hash[from] = { id: id, forwards: forwards, enabled: enabled }
      end
    end

    def self.update_route(id, forwards, enabled)
      mm = Multimap.new
      mm["action"] = STOP unless enabled
      forwards.each { |email| mm["action"] = "forward('#{email}')" }
      mm["action"] = STOP
      client.put "routes/#{id}", mm
    end

    def self.stats(start_date)
      stats = Hash.new { |h, k| h[k] = Hash.new(0) }
      client.get("icu.ie/stats", "start-date" => start_date.to_s, "limit" => 200).to_h["items"].each do |item|
        date = get_date(item)
        event = get_event(item)
        count = get_count(item)
        stats[date][event] = count
      end
      stats
    end

    def self.events(date)
      btime = Time.new(date.year, date.month, date.day, 0, 0, 0, "+00:00").rfc2822
      etime = Time.new(date.year, date.month, date.day, 24, 0, 0, "+00:00").rfc2822
      events = []
      next_page = nil

      (1..MAX_EVENTS_PAGES).each do |page_number|
        if next_page
          response = client.get("icu.ie/events/#{next_page}").to_h
        else
          response = client.get("icu.ie/events", begin: btime, end: etime, limit: MAX_EVENTS_PER_PAGE).to_h
        end

        page = Hash.new(0)
        first_time, last_time = nil, nil
        total = 0

        response["items"].each do |item|
          timestamp = item["timestamp"]
          last_time = Time.at(timestamp).utc if timestamp
          first_time = last_time if first_time.nil?
          event = item["event"]
          if event
            page[event] += 1
            total += 1
          end
        end

        page["total"] = total
        page["first_time"] = first_time
        page["last_time"] = last_time
        page["page"] = page_number

        events.push page

        break if total < MAX_EVENTS_PER_PAGE

        next_page = get_next_events_page(response)
      end

      events
    end

    def self.charge_reset(date)
      date.to_s.match(/-24\z/)
    end

    private

    def self.client(key="secret")
      ::Mailgun::Client.new Rails.application.secrets.mailgun[key]
    end

    def self.get_count(item)
      count = item["total_count"]
      raise "no valid count found in #{item}" unless count.is_a?(Fixnum) || count.match(/\A(0|[1-9]\d*)\z/)
      count.to_i
    end

    def self.get_date(item)
      Date.parse(item["created_at"]).to_s
    rescue
      raise "no valid date found in #{item}"
    end

    def self.get_event(item)
      event = item["event"]
      raise "no event found in #{item}" unless event
      event
    end

    def self.get_next_events_page(data)
      raise "no 'paging' hash found" unless data["paging"].is_a?(Hash)
      raise "no 'next' found in #{data['paging']}" unless data["paging"]["next"].present?
      m = data["paging"]["next"].match(/\Ahttps:\/\/api\.mailgun\.net\/v2\/icu\.ie\/events\/([^\s\/]+)/)
      raise "can't extract next page ID from #{data["paging"]["next"]}" unless m
      m[1]
    end

    private_class_method :client, :get_count, :get_date, :get_event, :get_next_events_page
  end
end
