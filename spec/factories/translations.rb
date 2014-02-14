FactoryGirl.define do
  factory :translation do
    locale      "ga"
    key         "hobby.programming"
    value       "cláir"
    english     "programming"
    old_english { english }
    active      true
    user        { Faker::Name.name }
  end
end
