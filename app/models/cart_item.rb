class CartItem < ActiveRecord::Base
  belongs_to :cart
  belongs_to :cartable, polymorphic: true, dependent: :destroy

  # Used in payment receipts.
  def to_s
    parts = []
    parts.push cartable.description
    parts.push cartable.player.name(id: true) if cartable.player.present?
    parts.push "€#{'%.2f' % cartable.cost}"
    parts.push I18n.t("shop.payment.status.#{cartable.status}", locale: :en) unless cartable.paid?
    parts.join(", ")
  end
end
