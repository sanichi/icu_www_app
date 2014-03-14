FactoryGirl.define do
  factory :subscripsion_item, class: Item::Subscripsion do
    player
    association    :fee, factory: :subscripsion_fee
    status         "unpaid"
    source         "www2"

    factory :paid_subscripsion_item do
      payment_method "stripe"
      status         "paid"
    end

    factory :nofee_subscripsion_item do
      fee            nil
      description    "Standard ICU Subscription 2012-13"
      cost           35.0
      start_date     Date.new(2012, 9, 1)
      end_date       Date.new(2013, 8, 31)

      factory :legacy_subscripsion_item do
        payment_method "paypal"
        status         "paid"
        source         "www1"
      end
    end

    factory :lifetime_subscripsion do
      fee            nil
      description    "Life Subscription"
      payment_method "free"
      status         "paid"
      source         "www1"
    end
  end
end
