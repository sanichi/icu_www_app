FactoryGirl.define do
  factory :subscription do
    player
    subscription_fee
    season_desc       { Season.new.to_s }
    source            "www2"
    status            "paid"
    category          "standard"
    payment_method    "stripe"
    cost              35.0
  end
end
