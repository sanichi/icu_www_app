FactoryGirl.define do
  factory :subscription do
    player
    subscription_fee
    season_desc      { Season.new.desc }
    category         :standard
    cost             35.0
    active           true
  end
end
