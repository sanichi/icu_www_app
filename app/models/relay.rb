class Relay < ActiveRecord::Base
  belongs_to :officer

  default_scope { order(:from) }
  scope :include_officer, -> { includes(:officer) }

  before_validation :complete_from

  validates :from, email: true, length: { maximum: 50 }, format: { with: /@icu\.ie\z/ }, uniqueness: true
  validates :from, :to, email: true, length: { maximum: 50 }, allow_nil: true
  validates :officer_id, presence: true

  private

  def complete_from
    if from.present? && !from.match(/@/)
      self.from += "@icu.ie"
    end
  end

  def self.refresh
    actuals = get_provider_relays
    Relay.all.each do |relay|
      if actual = actuals[relay.from]
        relay.update_column(:provider_id, actual[:id]) unless actual[:id] == relay.provider_id
        relay.update_column(:to, actual[:to])          unless actual[:to] == relay.to
      else
        relay.update_column(:provider_id, nil) unless relay.provider_id.nil?
        relay.update_column(:to, nil)          unless relay.to.nil?
      end
    end
    true
  rescue => e
    Failure.log("UpdateOfficerRedirects", exception: e.class.to_s, message: e.message)
    false
  end

  def self.get_provider_relays
    Util::Mailgun.routes.each_with_object({}) do |route, hash|
      next if route["expression"].match(/\Acatch_all/)
      if route["expression"].to_s.match(/\Amatch_recipient\(["'](\w+@icu\.ie)["']\)\z/)
        from = $1
      else
        raise "couldn't parse expression in #{route}"
      end
      if route["actions"].is_a?(Array) && route["actions"].first.to_s.match(/\Aforward\(["']([^"'\s]+)["']\)\z/)
        to = $1
      else
        raise "couldn't parse first action in #{route}"
      end
      if route["id"].present?
        id = route["id"]
      else
        raise "couldn't parse ID in #{route}"
      end
      hash[from] = { id: id, to: to }
    end
  end

  private_class_method :get_provider_relays
end
