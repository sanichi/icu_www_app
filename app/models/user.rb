class User < ActiveRecord::Base
  extend Util::Pagination
  attr_accessor :password

  OK = "OK"
  ROLES = %w[admin editor translator treasurer]
  MINIMUM_PASSWORD_LENGTH = 6
  SessionError = Class.new(RuntimeError)

  has_many :logins, dependent: :nullify

  before_validation :canonicalize_roles, :dont_remove_the_last_admin, :update_password_if_present

  validates :email, uniqueness: { case_sensitive: false }, format: { with: /@/ }
  validates :encrypted_password, :expires_on, :status, presence: true
  validates :salt, length: { is: 32 }
  validates :icu_id, numericality: { only_integer: true, greater_than: 0 }
  validates :roles, format: { with: /\A(#{ROLES.join('|')})( (#{ROLES.join('|')}))*\z/ }, allow_nil: true

  def valid_password?(password)
    encrypted_password == User.encrypt_password(password, salt)
  end

  def status_ok?
    status == OK
  end

  def verified?
    verified_at ? true : false
  end
  
  def verify
    verified? ? "yes" : "no"
  end

  def verify=(action)
    case action
    when "yes"
      self.verified_at = Time.now unless verified?
    when "no"
      self.verified_at = nil if verified?
    end
    verify
  end

  def subscribed?
    not expires_on.past?
  end
  
  def season_ticket
    t = SeasonTicket.new(icu_id, expires_on)
    t.valid? ? t.ticket : t.error
  end

  ROLES.each do |role|
    define_method "#{role}?" do
      roles.present? && (roles.include?(role) || roles.include?("admin"))
    end
  end
  
  def human_roles(options={})
    return "" if roles.blank?
    roles.split(" ").map do |role|
      ROLES.include?(role) ? I18n.t("user.role.#{role}", options) : role
    end.join(" ")
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
    case
    when params[:role] == "some"       then matches = matches.where("roles IS NOT NULL")
    when params[:role] == "none"       then matches = matches.where("roles IS NULL")
    when ROLES.include?(params[:role]) then matches = matches.where("roles LIKE ?", "%#{params[:role]}%")
    end
    case params[:expiry]
    when "Active"   then matches = matches.where("expires_on >= ?", Date.today.to_s)
    when "Expired"  then matches = matches.where("expires_on <  ?", Date.today.to_s)
    when "Extended" then matches = matches.where("expires_on >= ?", Date.today.years_since(2).end_of_year)
    end
    case params[:verify]
    when "Verified"   then matches = matches.where("verified_at IS NOT NULL")
    when "Unverified" then matches = matches.where(verified_at: nil)
    end
    paginate(matches, params, path)
  end

  def self.encrypt_password(password, salt)
    eval(APP_CONFIG["password_encryptor"])
  end

  def self.random_salt
    Digest::MD5.hexdigest(rand(1000000).to_s + Time.now.to_s)
  end

  def self.authenticate!(email, password, ip="127.0.0.1")
    raise SessionError.new("enter_email") if email.blank?
    raise SessionError.new("enter_password") if password.blank?
    user = User.find_by(email: email)
    self.add_login(ip, "invalid_email", email) unless user
    user.add_login(ip, "unverified_email")     unless user.verified?
    user.add_login(ip, "account_disabled")     unless user.status_ok?
    user.add_login(ip, "subscription_expired") unless user.subscribed?
    user.add_login(ip, "invalid_password")     unless user.valid_password?(password)
    user.add_login(ip)
  end

  def self.add_login(ip, error, email)
    Login.create(ip: ip, email: email, error: error)
    raise SessionError.new(error)
  end

  def add_login(ip, error=nil)
    logins.create(ip: ip, email: email, error: error, roles: roles)
    raise SessionError.new(error) if error
    self
  end
  
  def reason_to_not_delete
    case
    when roles.present? then "has special roles"
    else false
    end
  end

  private

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
  
  def dont_remove_the_last_admin
    if changed?
      if changed_attributes["roles"] == "admin"
        count = User.where(roles: "admin").where.not(id: id).count
        errors.add(:roles, "Can't remove the last #{I18n.t('user.role.admin')}") unless count > 0
      end
    end
  end

  def update_password_if_present
    if password.present?
      if password.length >= MINIMUM_PASSWORD_LENGTH
        if password.match(/\d/)
          self.salt = User.random_salt
          self.encrypted_password = User.encrypt_password(password, salt)
        else
          errors.add :password, I18n.t("errors.attributes.password.digits")
        end
      else
        errors.add :password, I18n.t("errors.attributes.password.length", minimum: MINIMUM_PASSWORD_LENGTH)
      end
    end
  end
end
