class User < ActiveRecord::Base
  attr_accessor :password

  ROLES = %w[admin editor translator treasurer]
  OK = "OK"
  
  before_validation :flatten_roles

  validates :email, uniqueness: { case_sensitive: false }, format: { with: /@/ }
  validates :encrypted_password, :expires_on, :status, presence: true
  validates :salt, length: { is: 32 }
  validates :icu_id, numericality: { only_integer: true, greater_than: 0 }
  validates :roles, format: { with: /\A(#{ROLES.join('|')})( (#{ROLES.join('|')}))*\z/ }, allow_nil: true
  validate :change_password_if_present

  def valid_password?(password)
    encrypted_password == User.encrypt_password(password, salt)
  end

  def status_ok?
    status == OK
  end

  def verified?
    verified_at
  end

  def subscribed?
    not expires_on.past?
  end

  def self.search(params)
    matches = order(:email)
    matches = matches.where("email LIKE ?", "%#{params[:email]}%") if params[:email].present?
    matches = matches.where(status: User::OK) if params[:status] == "OK"
    matches = matches.where.not(status: User::OK) if params[:status] == "Not OK"
    matches
  end

  def self.encrypt_password(password, salt)
    eval(APP_CONFIG["password_encryptor"])
  end

  def self.random_salt
    Digest::MD5.hexdigest(rand(1000000).to_s + Time.now.to_s)
  end
  
  SessionError = Class.new(RuntimeError)

  def self.authenticate!(email, password)
    user = User.find_by(email: email)
    raise SessionError.new("invalid_details")      unless user
    raise SessionError.new("unverified_email")     unless user.verified?
    raise SessionError.new("account_disabled")     unless user.status_ok?
    raise SessionError.new("subscription_expired") unless user.subscribed?
    raise SessionError.new("invalid_details")      unless user.valid_password?(password)
    user
  end

  def change_password_if_present
    if password.present?
      if password.length >= 6
        if password.match(/\d/)
          salt = User.random_salt
          encrypted_password = User.encrypt_password(password, salt)
        else
          errors.add :password, "password should contain at least 1 digit"
        end
      else
        errors.add :password, "password minimum length is 6"
      end
    end
  end
  
  def flatten_roles
    if roles.present? && roles.is_a?(Array)
      if roles.include?("admin")
        self.roles = "admin"
      else
        self.roles = roles.select{ |r| User::ROLES.include?(r) }.sort.join(" ")
        self.roles = nil if roles.blank?
      end
    end
  end
end
