class Item < ActiveRecord::Base
  def self.statuses
    %w[unpaid paid refunded]
  end
  include Payible

  belongs_to :player

  before_validation :copy_fee

  validates :description, presence: true
  validates :fee, presence: true, unless: Proc.new { |i| i.source == "www1" }
  validates :cost, presence: true, unless: Proc.new { |i| i.fee.blank? }
  validates :source, inclusion: { in: %w[www1 www2] }

  private

  def copy_fee
    return unless fee.present?
    self.description = fee.description(:full) unless description.present?
    self.start_date  = fee.start_date         unless start_date.present?
    self.end_date    = fee.end_date           unless end_date.present?
    self.cost        = fee.amount             unless cost.present?
  end
end
