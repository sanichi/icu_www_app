class User < ActiveRecord::Base
  extend Util::Pagination
  attr_accessor :password

  include Journalable
  journalize [:status, :encrypted_password, :roles], "/admin/users/%d"

  OK = "OK"
  ROLES = %w[admin editor membership translator treasurer]
  MINIMUM_PASSWORD_LENGTH = 6
  THEMES = %w[Bootstrap Cerulean Cosmo Cyborg Flatley Journal Readable Simplex Slate Spacelab]
  DEFAULT_THEME = "Flatley"
  LOCALES = %w[en ga]
  SessionError = Class.new(RuntimeError)

  has_many :logins, dependent: :destroy
  belongs_to :player

  default_scope { order(:email) }

  before_validation :canonicalize_roles, :dont_remove_the_last_admin, :update_password_if_present

  validates :email, uniqueness: { case_sensitive: false }, format: { with: /\A[^\s]+@[^\s]+\z/ }
  validates :encrypted_password, :expires_on, :status, presence: true
  validates :salt, length: { is: 32 }
  validates :player_id, numericality: { only_integer: true, greater_than: 0 }
  validates :roles, format: { with: /\A(#{ROLES.join('|')})( (#{ROLES.join('|')}))*\z/ }, allow_nil: true
  validates :theme, inclusion: { in: THEMES }, allow_nil: true
  validates :locale, inclusion: { in: LOCALES }

  def name
    player.name
  end

  def signature
    "#{name} (#{email})"
  end

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
    t = SeasonTicket.new(player_id, expires_on)
    t.valid? ? t.ticket : t.error
  end

  def preferred_theme
    theme || DEFAULT_THEME
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

    def name
      "Guest"
    end

    def guest?
      true
    end

    def roles
      nil
    end

    def preferred_theme
      DEFAULT_THEME
    end

    User::ROLES.each do |role|
      define_method "#{role}?" do
        false
      end
    end
  end

  def self.search(params, path)
    matches = includes(:player).references(:players)
    if params[:last_name].present? || params[:first_name].present?
      matches = matches.joins(:player)
      matches = matches.where("players.last_name LIKE ?", "%#{params[:last_name]}%") if params[:last_name].present?
      matches = matches.where("players.first_name LIKE ?", "%#{params[:first_name]}%") if params[:first_name].present?
    end
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
    raise SessionError.new("invalid_email")    unless user
    user.add_login(ip, "invalid_password")     unless user.valid_password?(password)
    user.add_login(ip, "unverified_email")     unless user.verified?
    user.add_login(ip, "account_disabled")     unless user.status_ok?
    user.add_login(ip, "subscription_expired") unless user.subscribed?
    user.add_login(ip)
  end

  def add_login(ip, error=nil)
    logins.create(ip: ip, error: error, roles: roles)
    raise SessionError.new(error) if error
    self
  end

  def self.locale?(locale)
    LOCALES.include?(locale.to_s)
  end

  def reason_to_not_delete
    case
    when roles.present?   then "has special roles"
    when logins.count > 0 then "has recorded logins"
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
