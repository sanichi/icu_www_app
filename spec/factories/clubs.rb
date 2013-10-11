# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :club do
    name      "Bangor Chess Club"
    web       nil
    meet      "Thurdsday night"
    address   nil
    district  nil
    city      "Bangor"
    county    "down"
    lat       { rand(51.4..55.4) }
    long      { rand(-10.4..-5.5) }
    contact   { Faker::Name.name }
    email     { Faker::Internet.email }
    phone     { Faker::PhoneNumber.phone_number }
    active    true
  end
end
