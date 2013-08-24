class User < ActiveRecord::Base
  serialize :permissions, Hash

  PERMISSIONS = %w[admin editor translator treasurer]
  OK = "OK"

  validates :email, uniqueness: { case_sensitive: false }, format: { with: /@/ }
  validates :encrypted_password, :expires_on, presence: true
  validates :salt, length: { is: 32 }
  validates :icu_id, numericality: { only_integer: true, greater_than: 0 }

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

  def self.encrypt_password(password, salt)
    eval(APP_CONFIG["password_encryptor"])
  end
  
  def self.random_salt
    Digest::MD5.hexdigest(rand(1000000).to_s + Time.now.to_s)
  end

  def self.authenticate!(email, password)
    user = User.find_by(email: email)
    raise "unknown_email"        unless user
    raise "unverified_email"     unless user.verified?
    raise "account_disabled"     unless user.status_ok?
    raise "subscription_expired" unless user.subscribed?
    raise "invalid_password"     unless user.valid_password?(password)
    user
  end
end
