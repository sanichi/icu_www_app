class Login < ActiveRecord::Base
  extend Util::Pagination

  belongs_to :user
  validates_presence_of :ip

  def self.search(params, path)
    matches = joins("LEFT OUTER JOIN users ON users.id = user_id")
    matches = matches.order(created_at: :desc)
    matches = matches.where("logins.ip LIKE ?", "%#{params[:ip]}%") if params[:ip].present?
    if params[:email].present?
      like = "%#{params[:email]}%"
      matches = matches.where("users.email LIKE ? OR logins.email LIKE ?", like, like)
    end
    paginate(matches, params, path, 20)
  end
end
