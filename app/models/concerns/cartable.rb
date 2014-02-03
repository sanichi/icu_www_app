module Cartable
  extend ActiveSupport::Concern

  included do
    has_one :cart_item, as: :cartable
  end
end
