class Officer < ActiveRecord::Base
  include Journalable
  journalize %w[executive emails player_id rank role], "/admin/officers/%d"

  belongs_to :player

  ROLES = %w[
    arbitration chairperson connaught development fide_ecu juniors leinster membership munster president
    publicrelations ratings secretary selections tournaments treasurer ulster vicechairperson webmaster women
  ]

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(rank: :asc, role: :asc) }
  scope :include_players, -> { includes(:player) }

  before_validation :normalize_emails, :default_emails

  validates :rank, numericality: { integer_only: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 100 }
  validates :role, inclusion: { in: ROLES }, uniqueness: true
  validates :emails, email_list: true

  def emails_array
    emails.split(" ")
  end

  def emails_with_redirects
    e = emails_array
    r = redirects.to_s.split(" ").map do |id_email|
      id_email.split(/\|/).last
    end
    r.size == e.size ? e.zip(r).map{ |pair| pair.join(" → ")} : e
  end

  def html_emails
    emails_array.map do |email|
      link = %Q[<a href="mailto:#{email}">#{email}</a>]
      "<script>liame(#{link.obscure})</script>"
    end.join(", ").html_safe
  end

  def self.update_redirects
    redirects = get_redirects
    Officer.all.each do |officer|
      emails = officer.emails_array
      matches = emails.map{ |email| redirects[email] }.compact
      officer.update_column(:redirects, matches.size == emails.size ? matches.join(" ") : nil)
    end
    true
  rescue => e
    Failure.log("UpdateOfficerRedirects", exception: e.class.to_s, message: e.message)
    false
  end

  private

  def normalize_emails
    if emails.present?
      emails.gsub!(/[,;\/\|]/, " ")
      emails.trim!
    end
  end

  def default_emails
    if emails.blank? && role.present?
      self.emails = role.split(/_/).map{ |prefix| "#{prefix}@icu.ie" }.join(" ")
    end
  end

  def self.get_redirects
    Util::Mailgun.routes.each_with_object({}) do |route, hash|
      next if route["expression"].match(/\Acatch_all/)
      if route["expression"].to_s.match(/\Amatch_recipient\(["'](\w+@icu\.ie)["']\)\z/)
        from = $1
      else
        raise "couldn't parse expression in #{route}"
      end
      if route["actions"].is_a?(Array) && route["actions"].first.to_s.match(/\Aforward\(["']([^"'\s]+)["']\)\z/)
        to = $1
      else
        raise "couldn't parse first action in #{route}"
      end
      if route["id"].present?
        id = route["id"]
      else
        raise "couldn't parse ID in #{route}"
      end
      hash[from] = "#{id}|#{to}"
    end
  end

  private_class_method :get_redirects
end
