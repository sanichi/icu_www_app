FactoryGirl.define do
  factory :cash_payment do
    first_name     { Faker::Name.first_name }
    last_name      { Faker::Name.last_name }
    email          { Faker::Internet.email }
    amount         "12.34"
    payment_method "cash"

    initialize_with { new(attributes) }
    skip_create
  end
end
