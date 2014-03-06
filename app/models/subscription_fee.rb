class SubscriptionFee < ActiveRecord::Base
  extend Util::Pagination
  include Journalable
  journalize %w[category amount season_desc], "/admin/subscription_fees/%d"

  has_many :subscriptions

  CATEGORIES = Subscription::CATEGORIES.reject { |cat| cat == "lifetime" }

  validates :category, inclusion: { in: CATEGORIES }, uniqueness: { scope: :season_desc, message: "no more than one per season" }
  validates :amount, numericality: { greater_than: 0.0 }
  validate :valid_season_desc

  after_save :reset_season

  scope :ordered, -> { order(season_desc: :desc, amount: :desc, category: :asc) }
  scope :on_sale, -> { where("sale_start <= ?", Date.today).where("sale_end >= ?", Date.today) }

  def self.search(params, path)
    matches = ordered
    paginate(matches, params, path, per_page: 10)
  end

  def description
    "#{season_desc} #{I18n.t("fee.subscription.category.#{category}")}"
  end

  def cost
    amount # no discounts for subscriptions
  end

  def season
    @season ||= Season.new(season_desc)
  end

  def deletable?
    subscriptions.count == 0
  end

  def rolloverable?
    return false if season.next > Season.new.next
    SubscriptionFee.where(category: category, season_desc: season.next.to_s).count == 0
  end

  def rollover
    return unless rolloverable?
    SubscriptionFee.create(category: category, season_desc: season.next.to_s, amount: amount)
  end

  private

  def valid_season_desc
    if season_desc.blank?
      errors.add(:season_desc, "can't be missing")
    else
      season = Season.new(season_desc)
      if season.error
        errors.add(:season_desc, season.error)
      elsif
        self.season_desc = season.to_s
        self.sale_start = season.start.months_ago(1)
        self.sale_end = season.end
        self.age_ref_date = season.start
      end
    end
  end

  def reset_season
    if previous_changes.has_key?("season_desc")
      @season = nil
    end
  end
end
