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
  validate :age_constraints, :rating_constraints

  private

  def copy_fee
    return unless fee.present?
    self.description = fee.description(:full) unless description.present?
    self.start_date  = fee.start_date         unless start_date.present?
    self.end_date    = fee.end_date           unless end_date.present?
    self.cost        = fee.amount             unless cost.present?
  end

  def age_constraints
    return unless [player, fee.try(:age_ref_date)].all?(&:present?)
    if fee.max_age.present? && player.over_age?(fee.max_age, fee.age_ref_date)
      errors.add(:base, I18n.t("item.error.age.old", member: player.name, date: fee.age_ref_date.to_s, limit: fee.max_age))
    end
    if fee.min_age.present? && player.under_age?(fee.min_age, fee.age_ref_date)
      errors.add(:base, I18n.t("item.error.age.young", member: player.name, date: fee.age_ref_date.to_s, limit: fee.min_age))
    end
  end

  def rating_constraints
    return unless [player, fee].all?(&:present?)
    if fee.max_rating.present? && player.too_strong?(fee.max_rating)
      errors.add(:base, I18n.t("item.error.rating.too_high", member: player.name, limit: fee.max_rating))
    end
    if fee.min_rating.present? && player.too_weak?(fee.min_rating)
      errors.add(:base, I18n.t("item.error.rating.too_low", member: player.name, limit: fee.min_rating))
    end
  end
end
