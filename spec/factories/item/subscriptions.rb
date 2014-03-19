FactoryGirl.define do
  factory :subscription_item, class: Item::Subscription do
    player
    association    :fee, factory: :subscription_fee
    status         "unpaid"
    source         "www2"

    factory :paid_subscription_item do
      payment_method "stripe"
      status         "paid"
    end

    factory :nofee_subscription_item do
      fee            nil
      description    "Standard ICU Subscription 2012-13"
      cost           35.0
      start_date     Date.new(2012, 9, 1)
      end_date       Date.new(2013, 8, 31)

      factory :legacy_subscription_item do
        payment_method "paypal"
        status         "paid"
        source         "www1"
      end
    end

    factory :lifetime_subscription do
      fee            nil
      description    "Life Subscription"
      payment_method "free"
      status         "paid"
      source         "www1"
    end
  end
end
