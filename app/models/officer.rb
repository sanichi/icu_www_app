class Officer < ActiveRecord::Base
  include Pageable # for journal items, not officers
  include Journalable
  journalize %w[executive player_id rank role], "/admin/officers/%d"

  belongs_to :player
  has_many :relays

  ROLES = %w[
    arbitration chairperson connaught development ecu fide fide_ecu juniors leinster membership munster president
    publicrelations ratings secretary selections tournaments treasurer ulster vicechairperson webmaster women
  ]

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(rank: :asc, role: :asc) }
  scope :include_players, -> { includes(:player) }

  validates :rank, numericality: { integer_only: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 100 }
  validates :role, inclusion: { in: ROLES }, uniqueness: true

  def emails
    relays.map(&:from)
  end

  def html_emails
    emails.map do |email|
      link = %Q[<a href="mailto:#{email}">#{email}</a>]
      "<script>liame(#{link.obscure})</script>"
    end.join(", ").html_safe
  end
end
