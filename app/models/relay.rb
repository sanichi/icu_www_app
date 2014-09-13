class Relay < ActiveRecord::Base
  belongs_to :officer

  default_scope { order(:from) }
  scope :include_officer, -> { includes(:officer) }

  before_validation :normalize_forwards

  validates :from, email: true, length: { maximum: 50 }, format: { with: /@icu\.ie\z/ }, uniqueness: true
  validates :to, email_list: true, length: { maximum: 255 }
  validates :provider_id, presence: true, length: { maximum: 255 }, uniqueness: true
  validates :officer_id, numericality: { integer_only: true, greater_than: 0 }, allow_nil: true

  def forwards
    to.split(/\s*,\s*/)
  end

  def update_route?
    Util::Mailgun.update_route(provider_id, forwards, enabled)
    true
  rescue => e
    Failure.log("UpdateMailProviderRoute", exception: e.class.to_s, message: e.message, provider_id: provider_id, from: from, to: to)
    false
  end

  def self.refresh
    actuals = get_provider_relays
    current = get_database_relays
    stats = Hash.new(0)
    actuals.each do |from, route|
      to = route[:forwards].empty?? nil : route[:forwards].sort.join(", ")
      provider_id = route[:id]
      enabled = route[:enabled]
      if relay = current[from]
        relay.to = to
        relay.provider_id = provider_id
        relay.enabled = enabled
        if relay.changed?
          relay.save!
          stats["updated"] += 1
        else
          stats["unchanged"] += 1
        end
      else
        Relay.create!(from: from, to: to, provider_id: provider_id, enabled: enabled)
        stats["created"] += 1
      end
    end
    current.each do |from, relay|
      unless actuals[from]
        relay.destroy
        stats["deleted"] += 1
      end
    end
    stats.empty?? "none found" : stats.map{ |k,v| "#{k}: #{v}" }.join(", ")
  rescue => e
    Failure.log("UpdateOfficerRedirects", exception: e.class.to_s, message: e.message)
    false
  end

  private

  def normalize_forwards
    if to.present?
      self.to = to.trim.gsub(/[\s,]+/, ", ")
    end
  end

  # The actual relays are what the provider defines.
  def self.get_provider_relays
    routes = Util::Mailgun.routes
    raise "unexpectedly low number of routes" unless routes.size > 20
    routes
  end

  # These are the relays currently in the ICU database which might be out of sync with the provider's.
  def self.get_database_relays
    Relay.all.each_with_object({}) do |relay, hash|
      hash[relay.from] = relay
    end
  end

  private_class_method :get_provider_relays, :get_database_relays
end
