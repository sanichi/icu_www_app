class Failure < ActiveRecord::Base
  include Pageable

  IGNORE = %w[ActiveRecord::RecordNotFound ActionController::UnknownFormat]

  scope :ordered, -> { order(created_at: :desc) }
  scope :active, -> { where(active: true) }

  before_create :normalize_details

  def self.examine(payload)
    name = payload[:exception].first
    unless IGNORE.include?(name)
      Failure.log(name, payload.dup)
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
