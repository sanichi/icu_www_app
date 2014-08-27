FactoryGirl.define do
  factory :article do
    access   "all"
    active   true
    category "general"
    text     { Faker::Lorem.paragraphs.join("\n\n") }
    title    { Faker::Lorem.sentence(4) }
    user
    year     { Date.today.year }
  end
end
