# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :club do
    name      "Bangor Chess Club"
    active    true
    meetings  "Thurdsday night"
    province  "ulster"
    county    "down"
    district  nil
    city      "Bangor"
    address   nil
    contact   { Faker::Name.name }
    phone     { Faker::PhoneNumber.phone_number }
    email     { Faker::Internet.email }
    web       nil
    latitude  { rand(51.4..55.4) }
    longitude { rand(-10.4..-5.5) }
  end
end
