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

  def route_updateable?
    return false unless self.class.route_update_allowed?(from)
    return false unless provider_id.present?
    return false unless previous_changes.keys.select{ |k| k.match(/\A(to|enabled)\z/) }.any?
    true
  end

  def self.route_update_allowed?(from)
    Rails.env.production? || (Rails.env.development? && from == "route_test@icu.ie")
  end

  def update_route?
    Util::Mailgun.update_route(provider_id, forwards, enabled)
    true
  rescue => e
    Failure.log("UpdateMailProviderRoute", exception: e.class.to_s, message: e.message, provider_id: provider_id, from: from, to: to)
    false
  end

  def self.refresh(actuals=nil)
    actuals ||= Util::Mailgun.routes
    current = Relay.all.each_with_object({}) { |relay, hash| hash[relay.from] = relay }
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
    Failure.log("UpdateOfficerRelays", exception: e.class.to_s, message: e.message)
    false
  end

  def self.toggle_all(on_or_off)
    routes = Util::Mailgun.toggle_all(on_or_off)
    refresh(routes)
    true
  rescue => e
    Failure.log("ToggleAllRelays#{on_or_off ? 'On' : 'Off'}", exception: e.class.to_s, message: e.message)
    false
  end

  private

  def normalize_forwards
    if to.present?
      self.to = to.trim.gsub(/[\s,]+/, ", ")
    end
  end
end
