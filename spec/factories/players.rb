FactoryGirl.define do
  factory :player do
    first_name      { Faker::Name.first_name }
    last_name       { Faker::Name.last_name }
    player_id       nil
    gender          "M"
    dob             Date.new(1955, 11, 9)
    joined          Date.new(1976, 9, 1)
    fed             "IRL"
    email           { Faker::Internet.email }
    address         nil
    player_title    nil
    arbiter_title   nil
    trainer_title   nil
    source          "officer"
    status          "active"
  end
end
