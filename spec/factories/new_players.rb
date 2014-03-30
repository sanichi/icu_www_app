FactoryGirl.define do
  factory :new_player do
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    gender     "M"
    dob        Date.new(1955, 11, 9)
    joined     Date.today
    fed        "IRL"
    email      { Faker::Internet.email }
    club_id    nil

    initialize_with { new(attributes) }
    skip_create
  end
end
