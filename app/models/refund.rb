class Refund < ActiveRecord::Base
  include Pageable

  belongs_to :cart
  belongs_to :user

  scope :include_player, -> { includes(user: :player) }
  scope :include_cart, -> { includes(:cart) }
  default_scope { order(created_at: :desc) }

  def self.search(params, path)
    matches = include_player.include_cart
    matches = matches.where(cart_id: params[:cart_id].to_i) if params[:cart_id].to_i > 0
    matches = matches.where(user_id: params[:user_id].to_i) if params[:user_id].to_i > 0
    matches = matches.where("created_at LIKE ?", "%#{params[:created_at]}%") if params[:created_at].present?
    matches = matches.where("error LIKE ?", "%#{params[:message]}%") if params[:message].present?
    paginate(matches, params, path)
  end
end
