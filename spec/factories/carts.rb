FactoryGirl.define do
  factory :cart do
    status            "unpaid"
    payment_completed nil
  end
end
