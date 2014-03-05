module Util
  class Mailgun
    def self.validate(address)
      result = client("public").get "address/validate", { address: address }
      result.to_h["is_valid"]
    end

    def self.client(key="private")
      ::Mailgun::Client.new APP_CONFIG["mailgun"][key]
    end

    private_class_method :client
  end
end
