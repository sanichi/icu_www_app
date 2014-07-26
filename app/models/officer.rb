class Officer < ActiveRecord::Base
  include Journalable
  journalize %w[executive emails player_id rank role], "/admin/officers/%d"

  belongs_to :player

  ROLES = %w[
    arbitration chairperson connaught development fide_ecu juniors leinster membership munster president
    publicrelations ratings secretary selections tournaments treasurer ulster vicechairperson webmaster women
  ]

  scope :ordered, -> { order(rank: :asc, role: :asc) }
  scope :include_players, -> { includes(:player) }

  before_validation :normalize_emails, :default_emails

  validates :rank, numericality: { integer_only: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 100 }
  validates :role, inclusion: { in: ROLES }, uniqueness: true
  validates :emails, format: { with: /\A#{Global::EMAIL}( #{Global::EMAIL})*\z/ }

  def html_emails
    emails.split(/ /).map do |email|
      link = %Q[<a href="mailto:#{email}">#{email}</a>]
      "<script>liame(#{link.obscure})</script>"
    end.join(", ").html_safe
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
end
