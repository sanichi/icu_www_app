module Util
  class Mailgun
    STOP = "stop()"
    NOT_APPLICABLE = /\A(catch_all|match_header)/
    CHARGEABLE = %w[received delivered dropped]
    MAX_EVENTS_PAGES = 10
    MAX_EVENTS_PER_PAGE = 300
    PROFILE = ChargeProfile.new(24, 10000, 0.0005, "USD")

    def self.validate(address)
      result = client("public").get "address/validate", { address: address }
      result.to_h["is_valid"]
    end

    def self.routes(min_expected=20)
      routes = client.get("routes").to_h["items"].each_with_object({}) do |route, hash|
        raise "no expression found in #{route}" unless route["expression"].present?
        next if route["expression"].match(NOT_APPLICABLE)
        if route["expression"].match(/\Amatch_recipient\(["'](\w+@icu\.ie)["']\)\z/)
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
      raise "unexpectedly low number of routes" unless routes.size >= min_expected
      routes
    end

    def self.update_route(id, forwards, enabled)
      mm = []
      mm.push ["action", STOP] unless enabled
      forwards.each { |email| mm.push ["action", "forward('#{email}')"] }
      mm.push ["action", STOP]
      client.put "routes/#{id}", mm.map{ |key,val| "#{CGI.escape(key)}=#{CGI.escape(val)}" }.join('&')
    end

    def self.toggle_all(on_or_off)
      # First, get all the live routes.
      routes = self.routes

      # Loop over them and update any that need it, if it's allowed from the current environment.
      routes.each do |from, data|
        id, forwards, enabled = %i[id forwards enabled].map { |key| data[key] }
        if on_or_off ^ enabled && ::Relay.route_update_allowed?(from)
          update_route(id, forwards, on_or_off)
          data[:enabled] = on_or_off
        end
      end

      # Finally, return the altered routes so the database can be updated.
      routes
    end

    def self.stats(start_date)
      stats = Hash.new { |h, k| h[k] = Hash.new(0) }
      client.get("icu.ie/stats", "start-date" => start_date.to_s, "limit" => 300).to_h["items"].each do |item|
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
      events = Hash.new(0)
      next_page, pages, total = nil, 0, 0

      (1..MAX_EVENTS_PAGES).each do |number|
        response = events_response(next_page, begin: btime, end: etime, limit: MAX_EVENTS_PER_PAGE).to_h

        page_total = 0
        response["items"].each do |item|
          event = item["event"]
          if event.present?
            if ::MailEvent::CODES[event.to_sym]
              events[event] += 1
            else
              events["other"] += 1
            end
            page_total += 1
          else
            raise "no 'event' found in item #{item}"
          end
        end

        pages += 1
        total += page_total
        break if page_total < MAX_EVENTS_PER_PAGE

        next_page = get_next_events_page(response, number)
      end

      events[:pages] = pages
      events[:total] = total
      events
    end

    def self.charge_for_last(hours)
      etime = Time.now.utc.rfc2822
      btime = (Time.now.utc - 3600 * hours).rfc2822
      next_page, total = nil, 0, 0

      (1..MAX_EVENTS_PAGES).each do |number|
        response = events_response(next_page, begin: btime, end: etime, limit: MAX_EVENTS_PER_PAGE, event: "accepted")

        page_total = response["items"].size
        total += page_total
        break if page_total < MAX_EVENTS_PER_PAGE

        next_page = get_next_events_page(response, number)
      end

      [total, PROFILE.cost(total, false)]
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

    def self.get_next_events_page(data, number)
      raise "no 'paging' hash found for page #{number}" unless data["paging"].is_a?(Hash)
      raise "no 'next' found in #{data['paging']} for page #{number}" unless data["paging"]["next"].present?
      m = data["paging"]["next"].match(/\Ahttps:\/\/api\.mailgun\.net\/v2\/icu\.ie\/events\/([^\s\/]+)/)
      raise "can't extract next page ID from #{data["paging"]["next"]} for page #{number}" unless m
      m[1]
    end

    def self.events_response(next_page, opts)
      if next_page
        response = client.get("icu.ie/events/#{next_page}").to_h
      else
        response = client.get("icu.ie/events", opts).to_h
      end
      raise "no 'items' array found for page #{number}" unless response["items"].is_a?(Array)
      response
    end

    private_class_method :client, :get_count, :get_date, :get_event, :get_next_events_page, :events_response
  end
end
