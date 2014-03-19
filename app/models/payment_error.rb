class PaymentError < ActiveRecord::Base
  extend Util::Pagination

  belongs_to :cart
  default_scope { order(:created_at) }

  def self.search(params, path)
    matches = all
    %w[message details payment_name confirmation_email created_at].each do |property|
      matches = matches.where("#{property} LIKE ?", "%#{params[property.to_sym]}%") if params[property.to_sym].present?
    end
    paginate(matches, params, path)
  end
end
