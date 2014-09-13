FactoryGirl.define do
  factory :relay do
    from        "webmaster@icu.ie"
    to          { Faker::Internet.email }
    provider_id { Faker::Lorem.characters(24) }
    enabled     true
    officer
  end
end
