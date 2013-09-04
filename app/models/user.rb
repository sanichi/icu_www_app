class User < ActiveRecord::Base
  extend Util::Pagination
  attr_accessor :password

  OK = "OK"
  ROLES = %w[admin editor translator treasurer]
  SessionError = Class.new(RuntimeError)

  has_many :logins

  before_validation :canonicalize_roles

  validates :email, uniqueness: { case_sensitive: false }, format: { with: /@/ }
  validates :encrypted_password, :expires_on, :status, presence: true
  validates :salt, length: { is: 32 }
  validates :icu_id, numericality: { only_integer: true, greater_than: 0 }
  validates :roles, format: { with: /\A(#{ROLES.join('|')})( (#{ROLES.join('|')}))*\z/ }, allow_nil: true
  validate  :update_password_if_present

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

  ROLES.each do |role|
    define_method "#{role}?" do
      roles.present? && (roles.include?(role) || roles.include?("admin"))
    end
  end

  def guest?
    false
  end

  class Guest
    def id
      "guest"
    end

    def guest?
      true
    end

    User::ROLES.each do |role|
      define_method "#{role}?" do
        false
      end
    end
  end

  def self.search(params, path)
    matches = order(:email)
    matches = matches.where("email LIKE ?", "%#{params[:email]}%") if params[:email].present?
    matches = matches.where(status: User::OK) if params[:status] == "OK"
    matches = matches.where.not(status: User::OK) if params[:status] == "Not OK"
    paginate(matches, params, path)
  end

  def self.encrypt_password(password, salt)
    eval(APP_CONFIG["password_encryptor"])
  end

  def self.random_salt
    Digest::MD5.hexdigest(rand(1000000).to_s + Time.now.to_s)
  end

  def self.authenticate!(email, password, ip="127.0.0.1")
    user = User.find_by(email: email)
    self.add_login(ip, "invalid_details", email) unless user
    user.add_login(ip, "unverified_email")       unless user.verified?
    user.add_login(ip, "account_disabled")       unless user.status_ok?
    user.add_login(ip, "subscription_expired")   unless user.subscribed?
    user.add_login(ip, "invalid_details")        unless user.valid_password?(password)
    user.add_login(ip)
  end

  def self.add_login(ip, error, email)
    Login.create(ip: ip, email: email, error: error)
    raise SessionError.new(error)
  end

  def add_login(ip, error=nil)
    logins.create(ip: ip, error: error, roles: roles)
    raise SessionError.new(error) if error
    self
  end

  private

  def update_password_if_present
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

  def canonicalize_roles
    if roles.present?
      self.roles = roles.scan(/\w+/) unless roles.is_a?(Array)
      if roles.include?("admin")
        self.roles = "admin"
      else
        self.roles = roles.select{ |r| User::ROLES.include?(r) }.sort.join(" ")
      end
    end
    self.roles = nil if roles.blank?
  end
end
