class PaymentError < ActiveRecord::Base
  belongs_to :cart
  default_scope { order(:created_at) }
  
  def self.params(error, name, email, opts={})
    message = opts[:message] || error.message || "Unknown error"
    details = error.try(:json_body)
    unless details.nil?
      details = details.fetch(:error) { details } if details.is_a?(Hash)
      details.delete(:message) if details.is_a?(Hash) && details[:message] == message
      details = details.to_s
    end
    { message: message, details: details, payment_name: name, confirmation_email: email }
  end
end
