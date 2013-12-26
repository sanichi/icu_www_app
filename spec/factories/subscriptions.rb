FactoryGirl.define do
  factory :subscription do
    player
    subscription_fee
    season_desc      { Season.new.desc }
    active           true
  end
end
