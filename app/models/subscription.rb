class Subscription < ActiveRecord::Base
  extend Util::Pagination
  include Cartable, Payable

  belongs_to :player
  belongs_to :subscription_fee

  CATEGORIES = %w[standard over_65 under_18 under_12 unemployed new_under_18 overseas lifetime]

  validates :player_id, numericality: { only_integer: true, greater_than: 0 }
  validates :subscription_fee_id, numericality: { only_integer: true, greater_than: 0 }, unless: Proc.new { |s| s.category == "lifetime" || s.source == "www1" }
  validates :category, inclusion: { in: CATEGORIES }
  validates :cost, numericality: { greater_than_or_equal: 0.0 }
  validates :source, inclusion: { in: %w[www1 www2] }

  validate :valid_season_desc, :no_duplicates, :right_age

  def season
    @season ||= Season.new(season_desc)
  end

  def description
    desc = []
    desc << I18n.t("fee.type.subscription")
    desc << season_desc unless category == "lifetime"
    desc << I18n.t("fee.subscription.category.#{category}")
    desc.join(" ")
  end

  def duplicate_of?(sub, add_error=false)
    if sub.player_id == player_id && sub.season_desc == season_desc
      errors.add(:base, I18n.t("fee.subscription.error.already_in_cart", member: player.name(id: true))) if add_error
      true
    else
      false
    end
  end

  def self.search(params, path)
    matches = includes(:player).references(:players).order(created_at: :desc)
    matches = matches.where(player_id: params[:player_id].to_i) if params[:player_id].to_i > 0
    matches = matches.where("players.last_name LIKE ?", "%#{params[:last_name]}%") if params[:last_name].present?
    matches = matches.where("players.first_name LIKE ?", "%#{params[:first_name]}%") if params[:first_name].present?
    matches = matches.where(category: params[:category]) if params[:category].present?
    matches = matches.where(season_desc: params[:season_desc] == "none" ? nil : params[:season_desc]) if params[:season_desc].present?
    case params[:payment_method]
    when "paid"
      matches = matches.active
    when "unpaid"
      matches = matches.inactive
    when *Cart::PAYMENT_METHODS
      matches = matches.where(payment_method: params[:payment_method])
    end
    paginate(matches, params, path)
  end

  private

  def valid_season_desc
    if season_desc.blank?
      self.season_desc = nil
    else
      season = Season.new(season_desc)
      if season.error
        errors.add(:season_desc, season.error)
      elsif
        self.season_desc = season.desc
      end
    end
  end

  def no_duplicates
    if player
      if season_desc && Subscription.active.where(player_id: player.id, season_desc: season_desc).where.not(id: id).count > 0
        errors.add(:base, I18n.t("fee.subscription.error.already_exists", member: player.name(id: true), season: season_desc))
      elsif Subscription.active.where(player_id: player.id, season_desc: nil).where.not(id: id).count > 0
        errors.add(:base, I18n.t("fee.subscription.error.lifetime_exists", member: player.name(id: true)))
      end
    end
  end

  def right_age
    return unless category.match(/(under|over)_\d+/)
    return unless player && player.dob.present? && subscription_fee && subscription_fee.age_ref_date.present?
    age = player.age(subscription_fee.age_ref_date)
    error, limit =
    case
    when age > 12 && category == "under_12"       then ["too_old", 12]
    when age < 65 && category == "over_65"        then ["too_young", 65]
    when age > 18 && category.match(/under_18\z/) then ["too_old", 18]
    end
    if error
      errors.add(:base, I18n.t("fee.subscription.error.#{error}", member: player.name(id: true), limit: limit, date: subscription_fee.age_ref_date.to_s))
    end
  end
end
