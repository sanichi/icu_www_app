module Util
  class Mailgun
    STOP = "stop()"
    CATCH_ALL = "catch_all()"

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

    def self.client(key="secret")
      ::Mailgun::Client.new Rails.application.secrets.mailgun[key]
    end

    private_class_method :client
  end
end
