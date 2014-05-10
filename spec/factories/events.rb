FactoryGirl.define do
  factory :event do
    name       "Ennis Congress"
    location   "West Country Hotels, Clare Road, Ennis"
    start_date { Date.today.days_since(30) }
    end_date   { Date.today.days_since(33) }
    contact    { Faker::Name.name }
    email      { Faker::Internet.email }
    phone      { Faker::PhoneNumber.phone_number }
    active     true
    category   "irish"
  end
end
