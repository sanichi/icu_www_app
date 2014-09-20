module Util
  class ChargeProfile
    include ActiveModel::Model

    attr_accessor :start_day, :allowance, :item_cost, :currency

    validates :start_day, numericality: { integer_only: true, greater_than: 0, less_than_or_equal_to: 31 }
    validates :allowance, numericality: { integer_only: true, greater_than_or_equal_to: 0 }
    validates :item_cost, numericality: { greater_than: 0.0 }
    validates :currency, format: { with: /\A[A-Z]{3}\z/ }

    def initialize(start_day, allowance, item_cost, currency)
      @start_day = start_day
      @allowance = allowance
      @item_cost = item_cost
      @currency  = currency
    end

    def cost(count, deduct_allowance=true)
      if deduct_allowance
        count <= allowance ? 0.0 : (count - allowance) * item_cost
      else
        count * item_cost
      end.round(2)
    end
  end
end
