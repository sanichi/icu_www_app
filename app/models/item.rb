class Item < ActiveRecord::Base
  def self.statuses
    %w[unpaid paid refunded]
  end
  include Payible

  belongs_to :player

  before_validation :copy_fee

  validates :source, inclusion: { in: %w[www1 www2] }
  validates :fee, presence: true, unless: Proc.new { |i| i.source == "www1" }
  validates :description, :cost, presence: true

  private

  def copy_fee
    return unless fee.present?
    self.description = fee.description(:full) unless description.present?
    self.start_date  = fee.start_date         unless start_date.present?
    self.end_date    = fee.end_date           unless end_date.present?
    self.cost        = fee.amount             unless cost.present?
  end
end
