class Failure < ActiveRecord::Base
  include Pageable

  scope :ordered, -> { order(created_at: :desc) }
  scope :active, -> { where(active: true) }

  before_create :normalize_details

  def self.examine(payload)
    unless ignore?(payload)
      Failure.log(payload[:exception].first, payload.dup)
    end
  end

  def self.search(params, path)
    matches = ordered
    matches = matches.where(active: params[:active] == "true") if params[:active].present?
    matches = matches.where("name LIKE ?", "%#{params[:name]}%") if params[:name].present?
    matches = matches.where("details LIKE ?", "%#{params[:details]}%") if params[:details].present?
    paginate(matches, params, path)
  end

  def self.log(name, details={})
    create(name: name, details: details)
  end

  def self.ignore?(payload)
    name = payload[:exception].first
    action = payload[:action].to_s
    if %w[ActiveRecord::RecordNotFound ActionController::UnknownFormat].include?(name)
      # Too common to log.
      true
    elsif name == "ActionController::InvalidAuthenticityToken" && action == "not_found"
      # Spammers POST-ing to non-existant URLs raises this instead of getting a 404.
      true
    elsif name == "ActionController::InvalidCrossOriginRequest" && action == "control"
      # Bots trying to follow the banner control button get this.
      true
    else
      false
    end
  end

  def snippet
    details.to_s.gsub(/\n/, " ").truncate(50)
  end

  private

  def normalize_details
    if details.is_a?(Hash)
      if details[:exception].is_a?(Array) && details[:exception].size == 2
        exception = details.delete(:exception)
        details[:name] = exception.first
        details[:message] = exception.last
      end
      self.details = details.map{ |key,val| "#{key}: #{val}" }.sort.join("\n")
    end
  end
end
