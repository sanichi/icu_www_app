FactoryGirl.define do
  factory :player do
    first_name      { Faker::Name.first_name }
    last_name       { Faker::Name.last_name }
    player_id       nil
    gender          "M"
    dob             Date.new(1955, 11, 9)
    joined          Date.new(1976, 9, 1)
    source          "officer"
    status          "active"
  end
end
