class BadLogin < ActiveRecord::Base
  include Pageable

  validates_presence_of :email, :encrypted_password, :ip

  def self.new_record(email, password, ip)
    create!(email: email, encrypted_password: Digest::MD5.hexdigest(password), ip: ip)
  end

  def self.search(params, path)
    matches = order(created_at: :desc)
    matches = matches.where("email LIKE ?", "%#{params[:email]}%") if params[:email].present?
    matches = matches.where("ip LIKE ?", "%#{params[:ip]}%") if params[:ip].present?
    matches = matches.where("created_at LIKE ?", "%#{params[:time]}%") if params[:time].present?
    paginate(matches, params, path)
  end
end
