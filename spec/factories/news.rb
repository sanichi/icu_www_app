FactoryGirl.define do
  factory :news do
    active   true
    summary  { Faker::Lorem.paragraphs.join("\n\n") }
    headline { Faker::Lorem.sentence }
    user
    date     { Date.today }
  end
end
