FactoryGirl.define do
  factory :episode do
    article
    series
    sequence(:number) { |n| n }
  end
end
