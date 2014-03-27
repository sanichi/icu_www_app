FactoryGirl.define do
  factory :player do
    first_name         { Faker::Name.first_name }
    last_name          { Faker::Name.last_name }
    gender             "M"
    dob                Date.new(1955, 11, 9)
    joined             Date.new(1976, 9, 1)
    fed                "IRL"
    email              { Faker::Internet.email }
    source             "officer"
    status             "active"

    factory :player_no_dob do
      dob    nil
      source "import"
    end
  end
end
