FactoryGirl.define do
  factory :subscription_fee, class: Fee::Subscription do
    active      true
    name        "Standard"
    amount      35.0
    years       { Season.new.to_s }
  end
end
