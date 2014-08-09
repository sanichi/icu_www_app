class Failure < ActiveRecord::Base
  include Pageable

  IGNORE = %w[ActiveRecord::RecordNotFound ActionController::UnknownFormat]

  scope :ordered, -> { order(created_at: :desc) }

  def self.examine(payload)
    name, message = payload[:exception]
    unless IGNORE.include?(name)
      details = payload.except(:exception).merge(name: name, message: message).map{ |k,v| "#{k}: #{v}" }.sort.join("\n")
      Failure.create!(name: name, details: details)
    end
  end

  def self.search(params, path)
    matches = ordered
    matches = matches.where("name LIKE ?", "%#{params[:name]}%") if params[:name].present?
    paginate(matches, params, path)
  end

  def snippet
    details.to_s.truncate(50)
  end
end
