module Util
  class Mailgun
    def self.validate(address)
      result = client("public").get "address/validate", { address: address }
      result.to_h["is_valid"]
    end

    def self.routes
      result = client.get "routes"
      result.to_h["items"]
    end

    def self.client(key="secret")
      ::Mailgun::Client.new Rails.application.secrets.mailgun[key]
    end

    private_class_method :client
  end
end
