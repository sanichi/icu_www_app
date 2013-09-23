class Login < ActiveRecord::Base
  extend Util::Pagination

  belongs_to :user
  validates_presence_of :ip, :email

  def self.search(params, path)
    matches = joins("LEFT OUTER JOIN users ON users.id = user_id")
    matches = matches.order(created_at: :desc)
    matches = matches.where("logins.ip LIKE ?", "%#{params[:ip]}%") if params[:ip].present?
    if params[:email].present?
      like = "%#{params[:email]}%"
      matches = matches.where("users.email LIKE ? OR logins.email LIKE ?", like, like)
    end
    case params[:result]
      when "Success"      then matches = matches.where(error: nil)
      when "Failure"      then matches = matches.where.not(error: nil)
      when "Bad email"    then matches = matches.where(error: "invalid_email")
      when "Bad password" then matches = matches.where(error: "invalid_password")
      when "Expired"      then matches = matches.where(error: "subscription_expired")
      when "Disabled"     then matches = matches.where(error: "account_disabled")
      when "Unverified"   then matches = matches.where(error: "unverified_email")
    end
    paginate(matches, params, path)
  end
end
