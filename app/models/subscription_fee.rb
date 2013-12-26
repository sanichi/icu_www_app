class SubscriptionFee < ActiveRecord::Base
  extend Util::Pagination
  include Journalable
  journalize %w[category amount season_desc], "/admin/subscription_fees/%d"

  CATEGORIES = %w[standard over_65 under_18 under_12 unemployed new_under_18]

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

  def full_description
    "#{I18n.t("fee.type.subscription", locale: :en)} #{season_desc} #{I18n.t("fee.subscription.category.#{category}", locale: :en)}"
  end

  def cost
    amount # no discounts for subscriptions
  end

  def season
    @season ||= Season.new(season_desc)
  end

  def rolloverable?
    return false if season.next > Season.new.next
    SubscriptionFee.where(category: category, season_desc: season.next).count == 0
  end

  def rollover
    return unless rolloverable?
    SubscriptionFee.create(category: category, season_desc: season.next, amount: amount)
  end

  def validate_cart_item(item)
    return unless error = case
    when item.player.nil?              then "missing_member"
    when player_already_in_cart?(item) then "already_in_cart"
    end
    I18n.t("fee.subscription.error.#{error}")
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
        self.season_desc = season.desc
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
  
  def player_already_in_cart?(item)
    item.cart.cart_items.detect do |cart_item|
      cart_item != item && cart_item.cartable_type == "SubscriptionFee" && cart_item.cartable.season_desc == season_desc
    end
  end
end
